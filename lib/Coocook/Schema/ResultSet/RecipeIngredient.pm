package Coocook::Schema::ResultSet::RecipeIngredient;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

sub sorted_by_columns { 'position' }

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::SortByName');

__PACKAGE__->meta->make_immutable;

sub prepared     { shift->search( { -bool     => 'prepare' } ) }
sub not_prepared { shift->search( { -not_bool => 'prepare' } ) }

1;
