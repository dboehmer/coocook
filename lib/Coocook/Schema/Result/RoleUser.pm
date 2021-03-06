package Coocook::Schema::Result::RoleUser;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('roles_users');

__PACKAGE__->add_columns(
    role    => { data_type => 'text' },
    user_id => { data_type => 'integer' },
);

__PACKAGE__->set_primary_key(qw< role user_id >);

__PACKAGE__->belongs_to( user => 'Coocook::Schema::Result::User', 'user_id' );

__PACKAGE__->meta->make_immutable;

1;
