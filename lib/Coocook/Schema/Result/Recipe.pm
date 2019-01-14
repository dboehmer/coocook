package Coocook::Schema::Result::Recipe;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("recipes");

__PACKAGE__->add_columns(
    id          => { data_type => 'int', is_auto_increment => 1 },
    project     => { data_type => 'int' },
    name        => { data_type => 'text' },
    preparation => { data_type => 'text' },
    description => { data_type => 'text' },
    servings    => { data_type => 'int' },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( [ 'project', 'name' ] );

__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project' );

__PACKAGE__->has_many( dishes => 'Coocook::Schema::Result::Dish', 'from_recipe' );

__PACKAGE__->has_many(
    ingredients => 'Coocook::Schema::Result::RecipeIngredient',
    'recipe',
    {
        cascade_copy => 1,
    }
);

__PACKAGE__->has_many( recipes_tags => 'Coocook::Schema::Result::RecipeTag' );
__PACKAGE__->many_to_many( tags => recipes_tags => 'tag' );

__PACKAGE__->meta->make_immutable;

sub duplicate {
    my ( $self, $args ) = @_;

    $args->{name} // die "no name defined in \$args";

    return $self->copy($args);
}

1;
