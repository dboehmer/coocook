package Coocook::Schema::Component::Result::Convertible;

# ABSTRACT: helper method for rows with article

use strict;
use warnings;

use parent 'DBIx::Class';

sub convertible_into {
    my $self = shift;

    return $self->article->units->search(
        {
            id       => { '!=' => $self->unit->id },
            quantity => $self->unit->quantity_id,
        }
    );
}

1;
