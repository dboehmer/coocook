package Coocook::Schema::Result::Recipe;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("recipes");

__PACKAGE__->add_columns(
    id          => { data_type => "integer", is_auto_increment => 1 },
    name        => { data_type => "text" },
    description => { data_type => "text" },
    servings    => { data_type => "int" },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
    ingredients => 'Coocook::Schema::Result::Ingredient',
    {
        'foreign.recipe' => 'self.id'
    }
);

__PACKAGE__->meta->make_immutable;

1;
