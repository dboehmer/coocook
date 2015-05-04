package Coocook::Schema::Result::Ingredient;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("ingredients");

__PACKAGE__->add_columns(
    id   => { data_type => "integer", is_auto_increment => 1 },
    name => { data_type => "text" },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->meta->make_immutable;

1;
