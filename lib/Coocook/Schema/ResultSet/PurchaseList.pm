package Coocook::Schema::ResultSet::PurchaseList;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::SortByName');
sub sorted_by_columns { 'date', 'name' }

__PACKAGE__->meta->make_immutable;

1;
