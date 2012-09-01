use utf8;

package Uninets::WebChat::Schema::Result::Role;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components('InflateColumn::DateTime');

__PACKAGE__->table('roles');

__PACKAGE__->add_columns(
    'id',
    {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => 'roles_id_seq',
    },
    'created_at',
    {
        data_type     => 'timestamp',
        default_value => \'current_timestamp',
        is_nullable   => 0,
        original      => { default_value => \'now()' },
    },
    'updated_at',
    {
        data_type     => 'timestamp',
        default_value => \'current_timestamp',
        is_nullable   => 0,
        original      => { default_value => \'now()' },
    },
    'name',
    {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 255
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( 'roles_name_key', ['name'] );

__PACKAGE__->has_many(
    'users',
    'Uninets::WebChat::Schema::Result::User',
    { 'foreign.role_id' => 'self.id' },
    {
        cascade_copy   => 0,
        cascade_delete => 1,
    },
);

1;
