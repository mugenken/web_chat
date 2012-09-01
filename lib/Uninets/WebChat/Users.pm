package Uninets::WebChat::Users;
use Mojo::Base 'Mojolicious::Controller';
use Email::Valid;

sub add {
    my $self = shift;

    $self->layout(undef) if $self->req->is_xhr;
    $self->render();
}

sub edit {
    my $self = shift;

    return 1;
}

sub create {
    my $self = shift;

    my $record = {};

    # validate email
    my $email = Email::Valid->address(
        -address  => $self->param('email'),
        -tldcheck => 1,
        -mxcheck  => 1,
    );

    unless ($email){
        $self->flash(
            class => 'alert alert-error',
            message => 'Email validation failed: ' . $Email::Valid::Details,
        );

        $self->redirect_to('/register');
    }

    # validate user
    my $login = $self->trim($self->param('login'));

    unless ($login){
        $self->flash(
            class   => 'alert alert-error',
            message => 'Username must not be empty!',
        );

        $self->redirect_to('/register');
    }

    my $user_exists = $self->model('User')->exists($login);

    if ($user_exists){
        $self->flash(
            class   => 'alert alert-error',
            message => 'Username exists!',
        );

        $self->redirect_to('/register');
    }

    # validate passwords
    unless ($self->param('password')){
        $self->flash(
            class   => 'alert alert-error',
            message => 'Password must not be empty!',
        );

        $self->redirect_to('/register');
    }

    if ($self->param('password') ne $self->param('password_verification')){
        $self->flash(
            class   => 'alert alert-error',
            message => 'Passwords do not match!',
        );

        $self->redirect_to('/register');
    }

    # fill the record
    if ($email && !$user_exists){
        $record->{email} = $email;
        $record->{login} = $self->param('login');
        $record->{password} = $self->encrypt_password($self->param('password'));
        $record->{activation_token} = $self->get_random_token();
    }

    if ($self->model('User')->save($record)){
        $self->flash(
            class   => 'alert alert-success',
            message => 'User registration successful!',
        );
        # TODO email notification
    }
    else {
        $self->flash(
            class   => 'alert alert-error',
            message => 'Oops. Something went wrong.',
        );
    }

    $self->redirect_to('/');
}

sub activate {
    my $self = shift;

    return 1;

}

sub read {
    my $self = shift;

    $self->render(userlist => $self->model('User')->get_all);
}

sub update {
    my $self = shift;

    return 1;

}

sub delete {
    my $self = shift;

    return 1;

}

1;
