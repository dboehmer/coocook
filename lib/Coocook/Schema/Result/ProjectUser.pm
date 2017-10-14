package Coocook::Schema::Result::ProjectUser;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("projects_users");

__PACKAGE__->add_columns(
    project => { data_type => 'int' },
    user    => { data_type => 'int' },
);

__PACKAGE__->set_primary_key(qw< project user >);

__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project' );
__PACKAGE__->belongs_to( user    => 'Coocook::Schema::Result::User' );

__PACKAGE__->meta->make_immutable;

1;
