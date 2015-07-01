package Coocook::Schema::ResultSet::Meal;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

# retrieves all dishes from all selected meals
sub dishes {
    my $self = shift;

    my $ids = $self->get_column('id')->as_query;

    return $self->result_source->schema->resultset('Dish')
      ->search( { meal => { -in => $ids } } );
}

__PACKAGE__->meta->make_immutable;

1;
