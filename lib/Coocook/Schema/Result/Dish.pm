package Coocook::Schema::Result::Dish;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("dishes");

__PACKAGE__->add_columns(
    id              => { data_type => 'int', is_auto_increment => 1 },
    meal            => { data_type => 'int' },
    from_recipe     => { data_type => 'int', is_nullable       => 1 },
    name            => { data_type => 'text' },
    servings        => { data_type => 'int' },
    prepare_at_meal => { data_type => 'int', is_nullable       => 1 },
    preparation     => { data_type => 'text' },
    description     => { data_type => 'text' },
    comment         => { data_type => 'text' },
);

__PACKAGE__->set_primary_key("id");

# TODO __PACKAGE__->add_unique_constraints([qw<meal name>]);

__PACKAGE__->belongs_to( meal => 'Coocook::Schema::Result::Meal' );

__PACKAGE__->belongs_to(
    prepare_at_meal => 'Coocook::Schema::Result::Meal',
    undef, { join_type => 'left' }
);

__PACKAGE__->belongs_to(
    recipe => 'Coocook::Schema::Result::Recipe',
    'from_recipe'
);

__PACKAGE__->has_many(
    ingredients => 'Coocook::Schema::Result::DishIngredient',
    undef,
    {
        cascade_delete => 1    # TODO this is default. but why does it not work?
    }
);

before delete => sub {         # TODO remove workaround!
    my $self = shift;

    $self->ingredients->delete();
};

__PACKAGE__->has_many(
    ingredients_ordered => 'Coocook::Schema::Result::DishIngredient',
    undef, { order_by => 'position' }
);

__PACKAGE__->has_many( dishes_tags => 'Coocook::Schema::Result::DishTag' );
__PACKAGE__->many_to_many( tags => dishes_tags => 'tag' );

__PACKAGE__->meta->make_immutable;

sub recalculate {
    my $self = shift;

    my $servings1 = $self->servings;
    my $servings2 = shift || die "servings undefined";

    $self->result_source->schema->txn_do(
        sub {
            for my $ingredient ( $self->ingredients->all ) {
                my $value1 = $ingredient->value;
                my $value2 = $value1 / $servings1 * $servings2;
                $ingredient->update( { value => $value2 } );
            }

            $self->update( { servings => $servings2 } );
        }
    );
}

1;
