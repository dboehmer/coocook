package Coocook::Schema::Component::ResultSet::ArticleOrUnit;

# ABSTRACT: methods shared between ResultSet::Article and ResultSet::Unit

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

=head2 in_use()

Returns a new resultset with articles/units which have any of
dish ingredients, recipe ingredients or purchase list items.

=cut

# TODO could this be self-relation 'in_use' in Article/Unit + 'units_in_use' in Article?
sub in_use {
    my $self = shift;

    my @relationships = qw<
      dish_ingredients
      recipe_ingredients
      items
    >;

    return $self->search(
        [    # OR
            map { $self->correlate($_)->search(@_)->results_exist_as_query } @relationships
        ]
    );
}

1;
