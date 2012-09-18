package Uninets::WebChat::Chat;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use DateTime;

sub window {
    my $self = shift;

    $self->redirect_to('/login') unless $self->session->{authenticated};

    $self->render();
}

sub socket {
    my $self = shift;

    my $name = $self->session->{user}->{login} . '@' . $self->tx->remote_address;
    my $clients = $self->clients($name, $self->tx);

    Mojo::IOLoop->stream($self->tx->connection)->timeout($self->config->{timeout});

    my $json = Mojo::JSON->new;

    $self->on(
        message => sub {
            my ($self, $msg) = @_;
            my $token = $self->config->{keep_alive_token};

            unless ($msg ~~ /$token/){
                my $dt   = DateTime->now( time_zone => 'Europe/Berlin' );

                for (keys %$clients){
                    $clients->{$_}->send(
                        $json->encode(
                            {
                                name => $name,
                                hms  => $dt->hms,
                                text => $msg,
                            }
                        )
                    );
                }
            }
        }
    );

    $self->on(
        finish => sub {
            my $self = shift;

            my $dt   = DateTime->now( time_zone => 'Europe/Berlin' );

            for (keys %$clients){
                $clients->{$_}->send(
                    $json->encode(
                        {
                            name => $name,
                            hms  => $dt->hms,
                            text => 'disconnected',
                        }
                    )
                );
            }
        }
    );
}

sub token {
    my $self = shift;
    my $json = Mojo::JSON->new;
    $self->render_json({token => $self->config->{keep_alive_token}});
}

sub timeout {
    my $self = shift;
    my $json = Mojo::JSON->new;
    # send timeout - 10% to the client
    # the client will never timeout as long as the browser window is open
    $self->render_json({timeout => int($self->config->{timeout} - $self->config->{timeout} * 0.1) });
}

1;
