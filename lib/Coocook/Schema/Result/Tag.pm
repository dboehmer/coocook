package Coocook::Schema::Result::Tag;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("tags");

__PACKAGE__->add_columns(
    id        => { data_type => "int", is_auto_increment => 1 },
    tag_group => { data_type => "int", is_nullable       => 1 },
    name      => { data_type => "text" },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( ['name'] );

__PACKAGE__->belongs_to( tag_group => 'Coocook::Schema::Result::TagGroup' );

__PACKAGE__->has_many( articles_tags => 'Coocook::Schema::Result::ArticleTag' );
__PACKAGE__->has_many( dishes_tags   => 'Coocook::Schema::Result::DishTag' );
__PACKAGE__->has_many( recipes_tags  => 'Coocook::Schema::Result::RecipeTag' );

__PACKAGE__->many_to_many( articles => articles_tags => 'article' );
__PACKAGE__->many_to_many( dishes   => dishes_tags   => 'dish' );
__PACKAGE__->many_to_many( recipes  => recipes_tags  => 'recipe' );

__PACKAGE__->meta->make_immutable;

1;
