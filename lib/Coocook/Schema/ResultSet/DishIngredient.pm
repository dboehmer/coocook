package Coocook::Schema::ResultSet::DishIngredient;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

sub prepared {
    my $self = shift;

    return $self->search( { $self->me('prepare') => 1 } );
}

sub unassigned {
    my $self = shift;

    return $self->search(
        undef,
        {
            join      => 'ingredients_items',
            distinct  => 1,
            '+select' => { count => 'ingredients_items.item', -as => 'count_items' },
            having => { count_items => { '=' => \'0' } },
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
