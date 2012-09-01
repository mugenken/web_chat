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

    my $name = $self->session->{user}->{login};
    my $clients = $self->clients($name, $self->tx);
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

1;
