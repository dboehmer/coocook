package Coocook::Schema::Result::Quantity;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("quantities");

__PACKAGE__->add_columns(
    id           => { data_type => 'int', is_auto_increment => 1 },
    name         => { data_type => 'text' },
    default_unit => { data_type => 'int', is_nullable       => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
    default_unit => 'Coocook::Schema::Result::Unit',
    { 'foreign.id' => 'self.default_unit' }
);

__PACKAGE__->has_many( units => 'Coocook::Schema::Result::Unit' );

__PACKAGE__->meta->make_immutable;

1;
