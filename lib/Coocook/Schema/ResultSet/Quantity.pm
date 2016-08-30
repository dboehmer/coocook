package Coocook::Schema::ResultSet::Quantity;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components('+Coocook::Schema::Component::SortByName');

__PACKAGE__->meta->make_immutable;

1;
