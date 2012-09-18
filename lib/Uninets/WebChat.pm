package Uninets::WebChat;
use Mojo::Base 'Mojolicious';

use lib 'lib';
use Uninets::WebChat::Schema;
use DBIx::Connector;
use YAML;
use String::Random;
use Crypt::Passwd::XS 'unix_sha512_crypt';

# This method will run once at server start
sub startup {
    my $self = shift;

    # configure
    my $config_file = 'config.yml';
    my $default_config = {
        database => {
            driver => 'Pg',
            dbuser => 'webchat',
            dbname => 'webchat',
            dbpass => 'webchat',
            dbhost => 'localhost',
        },
        session_secret => 'dQiGD3lE0CUwPQAXAod9hhi6sBSV0DqQDIWoPCd0Ukglu6NiA2maJWhVxfWPH05',
        keep_alive_token => '5a3a3316a166242932ea754c25',
        loglevel => 'debug',
        timeout => 300,
    };

    if ( -f $config_file ){
        $self->config( YAML::LoadFile($config_file) );
    }
    else {
        $self->config( $default_config );
    }

    $self->app->types->type(coffee => 'text/coffeescript; charset=utf-8');
    $self->secret( $self->config->{session_secret} // $default_config->{session_secret} );
    $self->app->log->level( $self->config->{loglevel} // $default_config->{loglevel} );

    # database connection
    die 'No database configuration!' unless defined $self->config->{database};
    my $dsn = 'dbi:' . $self->config->{database}->{driver} . ':dbname=' . $self->config->{database}->{dbname} . ';host=' . $self->config->{database}->{dbhost};
    my $connector = DBIx::Connector->new($dsn, $self->config->{database}->{dbuser}, $self->config->{database}->{dbpass});

    # holds websocket clients
    my $socket_clients = {};

    # helper functions
    my $helpers = {
        model => sub {
            my ($self, $resultset) = @_;
            my $dbh = Uninets::WebChat::Schema->connect( sub { return $connector->dbh; } );
            return $resultset ? $dbh->resultset($resultset) : $dbh;
        },
        get_random_token => sub {
            return String::Random::random_string('cCn' x 64);
        },
        encrypt_password => sub {
            my ($self, $plaintext) = @_;

            my $salt = String::Random::random_string('s' x 16);
            return Crypt::Passwd::XS::unix_sha512_crypt($plaintext, $salt);
        },
        user_authenticate => sub {
            my ($self, $user, $password) = @_;

            # get salt of user
            my $salt = (split /\$/, $user->{password})[2];

            # no salt? user does not exist
            return 0 unless $salt;

            # check if given pass salted and hashed matches
            return Crypt::Passwd::XS::unix_sha512_crypt($password, $salt) eq $user->{password} ? 1 : 0;
        },
        trim => sub {
            my ($self, $string) = @_;
            $string =~ s/^\s*(.*)\s*$/$1/gmx;

            return $string
        },
        check_user_permission => sub {
            my ($self, $check_id) = @_;

            return ($check_id == $self->session('user')->{id} || $self->session('role')->{name} eq 'admin') ? 1 : 0;
        },
        clients => sub {
            my ($self, $name, $client) = @_;

            $socket_clients->{$name} = $client if defined $name;

            return $socket_clients;
        },
    };

    # register helpers
    for (keys %$helpers){
        $self->helper( $_ => $helpers->{$_} );
    }

    # router
    my $r = $self->routes;

    # routing conditions
    my $conditions = {
        authenticated => sub {
            my ( $r, $self ) = @_;

            unless ( $self->session('authenticated') ) {
                $self->flash( class => 'alert alert-info', message => 'Please log in first!' );
                $self->redirect_to('/login');
                return;
            }

            return 1;
        },
        admin_role => sub {
            my ( $r, $self ) = @_;

            my $role = $self->session('role');
            unless ( $role->{name} eq 'admin' ) {
                $self->flash( class => 'alert alert-error', message => "You are no administrator" );
                $self->redirect_to('/login');
                return;
            }

            return 1;
        },
    };

    # add conditions
    for (keys %$conditions){
        $r->add_condition( $_ => $conditions->{$_} );
    }

    # user related
    $r->get('/register')->to('users#add');
    $r->get('/login')->to('auth#login');
    $r->get('/logout')->over('authenticated')->to('auth#logout');
    $r->post('/authenticate')->to('auth#authenticate');
    $r->post('/users/new')->to('users#create');
    $r->get('/users/list')->over('admin_role')->to('users#read');
    $r->get('/users/edit/:id')->over('authenticated')->to('users#edit');
    $r->get('/activate/:token')->to('users#activate');

    # chat
    $r->get('/')->to('chat#window');
    $r->get('/chat')->over('authenticated')->to('chat#window');
    $r->websocket('/socket')->over('authenticated')->to('chat#socket');
    $r->get('/token')->over('authenticated')->to('chat#token');
    $r->get('/timeout')->over('authenticated')->to('chat#timeout');

    # defaults
    $self->defaults( layout => 'uninets' );
}

1;
