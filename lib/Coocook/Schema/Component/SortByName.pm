package Coocook::Schema::Component::SortByName;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

sub sorted_by_column { 'name' }

sub sorted {
    my $self = shift;

    return $self->search(
        undef,
        {
            order_by => $self->me( $self->sorted_by_column ),
        }
    );
}

sub sorted_rs { scalar shift->sorted(@_) }

__PACKAGE__->meta->make_immutable;

1;
