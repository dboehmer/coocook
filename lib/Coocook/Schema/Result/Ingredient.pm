package Coocook::Schema::Result::Ingredient;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("ingredients");

__PACKAGE__->add_columns(
    id       => { data_type => "integer", is_auto_increment => 1 },
    recipe   => { data_type => "integer" },
    article  => { data_type => "integer" },
    unit     => { data_type => "integer" },
    quantity => { data_type => "real" },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->meta->make_immutable;

1;
