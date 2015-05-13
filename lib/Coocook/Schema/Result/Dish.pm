package Coocook::Schema::Result::Dish;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("dishes");

__PACKAGE__->add_columns(
    id          => { data_type => "int", is_auto_increment => 1 },
    meal        => { data_type => "int" },
    from_recipe => { data_type => "int", is_nullable       => 1 },
    name        => { data_type => "text" },
    servings    => { data_type => "int" },
    comment     => { data_type => "text" },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to( meal => 'Coocook::Schema::Result::Meal' );

__PACKAGE__->belongs_to(
    recipe => 'Coocook::Schema::Result::Recipe',
    'from_recipe'
);

__PACKAGE__->has_many(
    ingredients => 'Coocook::Schema::Result::DishIngredient' );

__PACKAGE__->meta->make_immutable;

1;
