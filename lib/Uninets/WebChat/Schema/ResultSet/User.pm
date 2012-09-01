package Uninets::WebChat::Schema::ResultSet::User;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use DBIx::Class::ResultClass::HashRefInflator;

sub find_as_hash {
    my ($self, $find) = @_;

    return $self->find( $find, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' } );
}

sub exists {
    my ($self, $username) = @_;

    my $user = $self->find( { login => $username } );

    return defined $user ? 1 : 0;
}

sub save {
    my ($self, $record) = @_;

    return $self->update_or_create($record);
}

sub get_all {
    my $self = shift;

    return [$self->all];
}

1;
