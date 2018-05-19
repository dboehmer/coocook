package Coocook::Schema::ResultSet::Terms;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->meta->make_immutable;

sub valid_today { shift->valid_on_date( DateTime->today ) }

sub valid_on_date {
    my ( $self, $date ) = @_;

    return $self->search( { valid_from => { '<=' => ref $date ? $self->format_date($date) : $date } },
        { order_by => { -DESC => 'valid_from' } } )->one_row;
}

1;
