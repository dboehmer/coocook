package Coocook::Schema::Result::User;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('users');

__PACKAGE__->add_columns(
    id           => { data_type => 'int', is_auto_increment => 1 },
    name         => { data_type => 'text' },
    password     => { data_type => 'text' },
    email        => { data_type => 'text' },
    display_name => { data_type => 'text' },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( ['name'] );

__PACKAGE__->has_many( projects_users => 'Coocook::Schema::Result::ProjectUser' );
__PACKAGE__->many_to_many( projects => projects_users => 'project' );

__PACKAGE__->meta->make_immutable;

1;
