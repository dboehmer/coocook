package Coocook::Schema::Result::Article;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('articles');

__PACKAGE__->add_columns(
    id                => { data_type => 'int', is_auto_increment => 1 },
    project_id        => { data_type => 'int' },
    shop_section_id   => { data_type => 'int', is_nullable => 1 },
    shelf_life_days   => { data_type => 'int', is_nullable => 1 },
    preorder_servings => { data_type => 'int', is_nullable => 1 },
    preorder_workdays => { data_type => 'int', is_nullable => 1 },
    name              => { data_type => 'text' },
    comment           => { data_type => 'text' },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint( [ 'project_id', 'name' ] );

__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project', 'project_id' );

__PACKAGE__->belongs_to(
    shop_section => 'Coocook::Schema::Result::ShopSection',
    'shop_section_id',
    {
        join_type => 'LEFT',
    }
);

__PACKAGE__->has_many(
    items => 'Coocook::Schema::Result::Item',
    'article_id',
    {
        cascade_delete => 0,    # articles with items may not be deleted
    }
);

__PACKAGE__->has_many( articles_tags => 'Coocook::Schema::Result::ArticleTag', 'article_id' );
__PACKAGE__->many_to_many( tags => articles_tags => 'tag' );

__PACKAGE__->has_many( articles_units => 'Coocook::Schema::Result::ArticleUnit', 'article_id' );
__PACKAGE__->many_to_many( units => articles_units => 'unit' );

__PACKAGE__->has_many(
    dish_ingredients => 'Coocook::Schema::Result::DishIngredient',
    'article_id',
    {
        cascade_delete => 0,    # articles with dish_ingredients may not be deleted
    }
);
__PACKAGE__->many_to_many( dishes => dish_ingredients => 'dish' );

__PACKAGE__->has_many(
    recipe_ingredients => 'Coocook::Schema::Result::RecipeIngredient',
    'article_id',
    {
        cascade_delete => 0,    # articles with recipe_ingredients may not be deleted
    }
);
__PACKAGE__->many_to_many( recipes => recipe_ingredients => 'recipe' );

__PACKAGE__->meta->make_immutable;

sub unit_ids_joined { # TODO move to ResultSet::Unit or optimize for non-cached 'units' relationship
    my $self      = shift;
    my $seperator = shift || ',';

    return join $seperator, map { $_->id } $self->units;
}

sub units_in_use {
    my $self = shift;

    return $self->units->in_use( { article_id => $self->id } );
}

sub tags_joined {
    my $self = shift;

    # TODO implement with get_column if not prefetched
    return join " ", map { $_->name } $self->tags;
}

1;
