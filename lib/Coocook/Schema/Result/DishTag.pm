package Coocook::Schema::Result::DishTag;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('dishes_tags');

__PACKAGE__->add_columns(
    dish_id => { data_type => 'integer' },
    tag_id  => { data_type => 'integer' },
);

__PACKAGE__->set_primary_key(qw<dish_id tag_id>);

__PACKAGE__->belongs_to( dish => 'Coocook::Schema::Result::Dish', 'dish_id' );
__PACKAGE__->belongs_to( tag  => 'Coocook::Schema::Result::Tag',  'tag_id' );

__PACKAGE__->meta->make_immutable;

1;
