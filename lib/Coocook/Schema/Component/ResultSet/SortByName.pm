package Coocook::Schema::Component::ResultSet::SortByName;

use strict;
use warnings;

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

1;
