package Coocook::Schema::Component::ResultSet::SortByName;

# ABSTRACT: provide simple $rs->sorted() with predefined sort order

use strict;
use warnings;

use mro 'c3';
use parent 'DBIx::Class::ResultSet';

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
