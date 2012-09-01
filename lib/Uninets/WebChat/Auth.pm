package Uninets::WebChat::Auth;
use Mojo::Base 'Mojolicious::Controller';

sub login {
    my $self = shift;
    $self->render();
}

sub authenticate {
    my $self = shift;

    my $username = $self->param('username');
    my $password = $self->param('password');

    my $user = $self->model('User')->find_as_hash({ login => $username });
    my $role = $self->model('Role')->find_as_hash( $user->{role_id} );

    if ($self->user_authenticate($user, $password)){
        $self->session( user => undef, authenticated => undef, role => undef );
        delete $user->{password};
        $self->session(
            authenticated => 1,
            user => $user,
            role => $role ? $role : { name => 'none' },
        );

        $self->flash( class => 'alert alert-success', message => 'Login successful!' );
    }
    else {
        $self->flash( class => 'alert alert-error', message => 'Login failed!' );
    }

    $self->redirect_to('/');
}

sub logout {
    my $self = shift;

    $self->session( user => undef, authenticated => undef, role => undef );
    $self->flash( class => 'alert alert-success', message => 'Logout successful!' );

    $self->redirect_to('/');
}
1;
