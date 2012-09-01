use utf8;

package Uninets::WebChat::Schema::Result::User;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components('InflateColumn::DateTime');

__PACKAGE__->table('users');

__PACKAGE__->add_columns(
    'id',
    {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => 'users_id_seq',
    },
    'role_id',
    {
        data_type      => 'integer',
        is_foreign_key => 1,
        is_nullable    => 1,
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
    'login',
    {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 255,
    },
    'email',
    {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 255,
    },
    'active',
    {
        data_type     => 'integer',
        default_value => 0,
        is_nullable   => 0,
    },
    'activation_token',
    {
        data_type     => 'varchar',
        is_nullable   => 1,
        size          => 255,
        default_value => 'none',
    },
    'password',
    {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 255,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( 'user_login_key', ['login'] );

__PACKAGE__->belongs_to(
    'role',
    'Uninets::WebChat::Schema::Result::Role',
    { id => 'role_id', },
    {
        is_deferrable => 1,
        join_type     => 'LEFT',
        on_delete     => 'CASCADE',
        on_update     => 'CASCADE',
    },
);

1;
