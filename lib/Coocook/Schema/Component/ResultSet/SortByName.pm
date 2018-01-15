package Coocook::Schema::Component::ResultSet::SortByName;

# ABSTRACT: provide simple $rs->sorted() with predefined sort order

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
