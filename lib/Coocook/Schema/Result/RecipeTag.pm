package Coocook::Schema::Result::RecipeTag;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("recipes_tags");

__PACKAGE__->add_columns(
    recipe => { data_type => 'int' },
    tag    => { data_type => 'int' },
);

__PACKAGE__->set_primary_key(qw<recipe tag>);

__PACKAGE__->belongs_to( recipe => 'Coocook::Schema::Result::Recipe' );
__PACKAGE__->belongs_to( tag    => 'Coocook::Schema::Result::Tag' );

__PACKAGE__->meta->make_immutable;

1;
