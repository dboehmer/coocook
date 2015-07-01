package Coocook::Schema::Result::DishTag;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("dishes_tags");

__PACKAGE__->add_columns(
    dish => { data_type => 'int' },
    tag  => { data_type => 'int' },
);

__PACKAGE__->set_primary_key(qw<dish tag>);

__PACKAGE__->belongs_to( dish => 'Coocook::Schema::Result::Dish' );
__PACKAGE__->belongs_to( tag  => 'Coocook::Schema::Result::Tag' );

__PACKAGE__->meta->make_immutable;

1;
