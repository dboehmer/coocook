package Coocook::Schema::Result::QuantityUnit;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("quantities_units");

__PACKAGE__->add_columns(
    quantity   => { data_type => "int" },
    unit       => { data_type => "int" },
    to_default => { data_type => "real" }
    ,    # factor for converting to default unit
);

__PACKAGE__->set_primary_key(qw<quantity unit>);

__PACKAGE__->add_unique_constraint( ['unit'] );

__PACKAGE__->meta->make_immutable;

1;
