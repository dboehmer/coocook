package Coocook::Schema::ResultSet::DishIngredient;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

sub sorted_by_columns { 'position' }

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::SortByName');

__PACKAGE__->meta->make_immutable;

sub prepared {
    my $self = shift;

    return $self->search( { -bool => $self->me('prepare') } );
}

sub unassigned {
    my $self = shift;

    return $self->search( { item => undef } );
}

1;
