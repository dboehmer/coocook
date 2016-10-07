package Coocook::Schema::ResultSet::Unit;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

sub sorted_by_column { 'short_name' }

__PACKAGE__->load_components('+Coocook::Schema::Component::SortByName');

__PACKAGE__->meta->make_immutable;

1;
