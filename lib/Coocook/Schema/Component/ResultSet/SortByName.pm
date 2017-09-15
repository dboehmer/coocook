package Coocook::Schema::Component::ResultSet::SortByName;

use strict;
use warnings;

sub sorted_by_columns { 'name' }

sub sorted {
    my $self = shift;

    return $self->search(
        undef,
        {
            order_by => [ map { $self->me($_) } $self->sorted_by_columns ],
        }
    );
}

1;
