package Coocook::Schema::ResultSet::DishIngredient;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->meta->make_immutable;

sub prepared {
    my $self = shift;

    return $self->search( { $self->me('prepare') => 1 } );
}

sub unassigned {
    my $self = shift;

    return $self->search( { item => undef } );
}

1;
