package Uninets::WebChat::Schema::ResultSet::Role;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use DBIx::Class::ResultClass::HashRefInflator;

sub find_as_hash {
    my ($self, $find) = @_;

    return $self->find( $find, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' } );
}

1;
