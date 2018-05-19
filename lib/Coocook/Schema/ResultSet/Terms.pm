package Coocook::Schema::ResultSet::Terms;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->meta->make_immutable;

sub valid_on_date_rs {
    my ( $self, $date ) = @_;

    return $self->search( { valid_from => { '<=' => ref $date ? $self->format_date($date) : $date } },
        { order_by => { -DESC => 'valid_from' } } );
}

sub valid_on_date { shift->valid_on_date_rs(@_)->one_row }

sub valid_today_rs { shift->valid_on_date_rs( DateTime->today ) }

sub valid_today { shift->valid_on_date_rs( DateTime->today )->one_row }

1;
