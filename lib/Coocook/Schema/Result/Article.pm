package Coocook::Schema::Result::Article;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("articles");

__PACKAGE__->add_columns(
    id                => { data_type => 'int', is_auto_increment => 1 },
    project           => { data_type => 'int' },
    shop_section      => { data_type => 'int', is_nullable => 1 },
    shelf_life_days   => { data_type => 'int', is_nullable => 1 },
    preorder_servings => { data_type => 'int', is_nullable => 1 },
    preorder_workdays => { data_type => 'int', is_nullable => 1 },
    name              => { data_type => 'text' },
    comment           => { data_type => 'text' },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( [ 'project', 'name' ] );

__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project' );

__PACKAGE__->belongs_to(
    shop_section => 'Coocook::Schema::Result::ShopSection',
    undef, { join_type => 'LEFT' }
);

__PACKAGE__->has_many( items => 'Coocook::Schema::Result::Item' );

__PACKAGE__->has_many( articles_tags => 'Coocook::Schema::Result::ArticleTag' );
__PACKAGE__->many_to_many( tags => articles_tags => 'tag' );

__PACKAGE__->has_many( articles_units => 'Coocook::Schema::Result::ArticleUnit' );
__PACKAGE__->many_to_many( units => articles_units => 'unit' );

__PACKAGE__->has_many( dish_ingredients => 'Coocook::Schema::Result::DishIngredient' );
__PACKAGE__->many_to_many( dishes => dish_ingredients => 'dish' );

__PACKAGE__->has_many( recipe_ingredients => 'Coocook::Schema::Result::RecipeIngredient' );
__PACKAGE__->many_to_many( recipes => recipe_ingredients => 'recipe' );

__PACKAGE__->meta->make_immutable;

sub unit_ids_joined { # TODO move to ResultSet::Unit or optimize for non-cached 'units' relationship
    my $self      = shift;
    my $seperator = shift || ',';

    return join $seperator, map { $_->id } $self->units;
}

sub units_in_use {
    my $self = shift;

    return $self->units->in_use( { article => $self->id } );
}

sub tags_joined {
    my $self = shift;

    # TODO implement with get_column if not prefetched
    return join " ", map { $_->name } $self->tags;
}

1;
