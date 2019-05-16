package Coocook::Schema::Result::Unit;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("units");

__PACKAGE__->add_columns(
    id                  => { data_type => 'int', is_auto_increment => 1 },
    project             => { data_type => 'int' },
    quantity            => { data_type => 'int', is_nullable => 0 },
    to_quantity_default => { data_type => 'real', is_nullable => 1 },
    space               => { data_type => 'bool' },
    short_name          => { data_type => 'text' },
    long_name           => { data_type => 'text' },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( [ 'project', 'long_name' ] );

__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project' );

__PACKAGE__->belongs_to( quantity => 'Coocook::Schema::Result::Quantity' );

# returns other convertible units of same quantity but not $self,
# for doc see https://metacpan.org/pod/DBIx::Class::Relationship::Base#Custom-join-conditions
__PACKAGE__->has_many(
    convertible_into => 'Coocook::Schema::Result::Unit',
    sub {
        my $args = shift;

        return {
            "$args->{foreign_alias}.id"       => { '!='   => { -ident => "$args->{self_alias}.id" } },
            "$args->{foreign_alias}.quantity" => { -ident => "$args->{self_alias}.quantity" },
            "$args->{foreign_alias}.to_quantity_default" => { '!=' => undef },
        };
    }
);

# returns other units of same quantity except $self--regardless if convertible or not
__PACKAGE__->has_many(
    other_units_of_same_quantity => 'Coocook::Schema::Result::Unit',
    sub {
        my $args = shift;

        return {
            "$args->{foreign_alias}.id"       => { '!='   => { -ident => "$args->{self_alias}.id" } },
            "$args->{foreign_alias}.quantity" => { -ident => "$args->{self_alias}.quantity" },
        };
    }
);

__PACKAGE__->has_many(
    articles_units => 'Coocook::Schema::Result::ArticleUnit',
    'unit',
    {
        cascade_delete => 0,    # units with articles_units may not be deleted
    }
);
__PACKAGE__->many_to_many( articles => articles_units => 'article' );

__PACKAGE__->has_many(
    dish_ingredients => 'Coocook::Schema::Result::DishIngredient',
    'unit',
    {
        cascade_delete => 0,    # units with dish_ingredients may not be deleted
    }
);
__PACKAGE__->many_to_many( dishes => dish_ingredients => 'dish' );

__PACKAGE__->has_many(
    recipe_ingredients => 'Coocook::Schema::Result::RecipeIngredient',
    'unit',
    {
        cascade_delete => 0,    # units with recipe_ingredients may not be deleted
    }
);
__PACKAGE__->many_to_many( recipes => recipe_ingredients => 'recipe' );

__PACKAGE__->has_many(
    items => 'Coocook::Schema::Result::Item',
    'unit',
    {
        cascade_delete => 0,    # units with items may not be deleted
    }
);

# before deleting a single unit
# we need to unset default_unit for the quantity if it's the last unit
# because then the quantitiy's default unit cannot be switched to any other unit
before delete => sub {
    my $self = shift;

    if ( $self->is_quantity_default ) {
        $self->other_units_of_same_quantity->exists
          or $self->quantity->update( { default_unit => undef } );
    }
};

__PACKAGE__->meta->make_immutable;

sub can_be_quantity_default {
    my $self = shift;

    $self->get_column('quantity')  or return;
    $self->get_to_quantity_default or return;

    return 1;
}

sub is_quantity_default {
    my $self = shift;

    return ( $self->id == $self->quantity->get_column('default_unit') );
}

# marks this unit as its quantity's default and adjusts conversion factors of all units
sub make_quantity_default {
    my $self = shift;

    my $quantity = $self->quantity            or die "No quantity";
    my $factor   = $self->to_quantity_default or die "No to_quantity_default";
    my $orig     = $quantity->default_unit;

    if ( not $orig ) {    # no previous default->just select this unit
        return $quantity->update( { default_unit => $self->id } );
    }

    $orig->id == $self->id and return 1;    # already default

    $orig->to_quantity_default == 1
      or die "Original default unit needs factor 1";

    # collect convertible units of this quantity except $self and $orig
    my $others = $quantity->units->search(
        {
            id                  => { -not_in => [ $self->id, $orig->id ] },
            to_quantity_default => { '!='    => undef },                      # IS NOT NULL
        }
    );

    $self->txn_do(
        sub {
            for my $unit ( $others->all ) {
                $unit->update(
                    {
                        to_quantity_default => $unit->to_quantity_default / $factor
                    }
                );
            }

            $orig->update( { to_quantity_default => 1 / $factor } );
            $self->update( { to_quantity_default => 1 } );

            $quantity->update( { default_unit => $self->id } );
        }
    );

    return 1;
}

1;
