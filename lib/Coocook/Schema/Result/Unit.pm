package Coocook::Schema::Result::Unit;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("units");

__PACKAGE__->add_columns(
    id                  => { data_type => "int",  is_auto_increment => 1 },
    quantity            => { data_type => "int",  is_nullable       => 1 },
    to_quantity_default => { data_type => "real", is_nullable       => 1 },
    short_name          => { data_type => "text" },
    long_name           => { data_type => "text" },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to( quantity => 'Coocook::Schema::Result::Quantity' );

__PACKAGE__->meta->make_immutable;

1;
