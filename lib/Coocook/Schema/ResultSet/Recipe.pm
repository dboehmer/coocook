package Coocook::Schema::ResultSet::Recipe;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::SortByName');

__PACKAGE__->meta->make_immutable;

# retrieves all ingredients from all selected recipes
sub ingredients {
    my $self = shift;

    my $ids = $self->get_column('id')->as_query;

    return $self->result_source->schema->resultset('RecipeIngredient')
      ->search( { $self->me('recipe') => { -in => $ids } } );
}

1;
