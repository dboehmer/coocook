package Coocook::Schema::Result::Dish;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("dishes");

__PACKAGE__->add_columns(
    id              => { data_type => "int", is_auto_increment => 1 },
    meal            => { data_type => "int" },
    from_recipe     => { data_type => "int", is_nullable       => 1 },
    name            => { data_type => "text" },
    servings        => { data_type => "int" },
    prepare_at_meal => { data_type => "int", is_nullable       => 1 },
    preparation     => { data_type => "text" },
    description     => { data_type => "text" },
    comment         => { data_type => "text" },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to( meal => 'Coocook::Schema::Result::Meal' );

__PACKAGE__->belongs_to( prepare_at_meal => 'Coocook::Schema::Result::Meal' );

__PACKAGE__->belongs_to(
    recipe => 'Coocook::Schema::Result::Recipe',
    'from_recipe'
);

__PACKAGE__->has_many(
    ingredients => 'Coocook::Schema::Result::DishIngredient' );

__PACKAGE__->has_many( dishes_tags => 'Coocook::Schema::Result::DishTag' );
__PACKAGE__->many_to_many( tags => dishes_tags => 'tag' );

__PACKAGE__->meta->make_immutable;

sub recalculate {
    my ( $self, $servings ) = @_;

    $servings ||= $self->servings || die "servings undefined";

    my $recipe = $self->recipe;

    $self->result_source->schema->txn_do(
        sub {
            for my $ingredient ( $recipe->ingredients ) {
                my $i = $self->find_or_new_related(
                    ingredients => {
                        article => $ingredient->article,
                        unit    => $ingredient->unit,
                    }
                );
                $i->value( $ingredient->value / $recipe->servings * $servings );
                $i->in_storage or $i->comment("");
                $i->update_or_insert;
            }

            $self->update( { servings => $servings } );
        }
    );
}

1;
