package Coocook::Schema::Result::GroupUser;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('groups_users');

__PACKAGE__->add_columns(
    group => { data_type => 'int' },
    user  => { data_type => 'int' },
    role  => { data_type => 'text' },
);

__PACKAGE__->set_primary_key(qw< group user >);

__PACKAGE__->belongs_to( group => 'Coocook::Schema::Result::Group' );
__PACKAGE__->belongs_to( user  => 'Coocook::Schema::Result::User' );

__PACKAGE__->meta->make_immutable;

1;
