package Coocook::Schema::ResultSet::Meal;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

sub order_by_columns { qw< date id > }    # TODO add sorting of meals

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::SortByName');

__PACKAGE__->meta->make_immutable;

1;
