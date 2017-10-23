package Coocook::Schema::Result::User;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('users');

__PACKAGE__->add_columns(
    id             => { data_type => 'int',      is_auto_increment => 1 },
    name           => { data_type => 'text' },
    password_hash  => { data_type => 'text' },
    display_name   => { data_type => 'text' },
    role           => { data_type => 'text' },
    email          => { data_type => 'text' },
    email_verified => { data_type => 'datetime', is_nullable       => 1 },
    token          => { data_type => 'text',     is_nullable       => 1 },
    token_expires  => { data_type => 'datetime', is_nullable       => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( ['name'], ['token'] );

__PACKAGE__->has_many( owned_projects => 'Coocook::Schema::Result::Project' );

__PACKAGE__->has_many( projects_users => 'Coocook::Schema::Result::ProjectUser' );
__PACKAGE__->many_to_many( projects => projects_users => 'project' );

__PACKAGE__->meta->make_immutable;

1;
