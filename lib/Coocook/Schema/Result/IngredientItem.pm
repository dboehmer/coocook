package Coocook::Schema::Result::IngredientItem;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("ingredients_items");

__PACKAGE__->add_columns(
    ingredient => { data_type => 'int' },
    item       => { data_type => 'int' },
);

__PACKAGE__->set_primary_key(qw<ingredient item>);

__PACKAGE__->belongs_to( ingredient => 'Coocook::Schema::Result::DishIngredient' );
__PACKAGE__->belongs_to( item       => 'Coocook::Schema::Result::Item' );

__PACKAGE__->meta->make_immutable;

1;
