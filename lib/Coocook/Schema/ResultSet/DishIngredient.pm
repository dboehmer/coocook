package Coocook::Schema::ResultSet::DishIngredient;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

sub prepared {
    my $self = shift;

    return $self->search( { prepare => 1 } );
}

__PACKAGE__->meta->make_immutable;

1;
