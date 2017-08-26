package Coocook::Schema::ResultSet::Article;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::SortByName');

__PACKAGE__->meta->make_immutable;

# retrieves all articles_units from all selected articles
sub articles_units {
    my $self = shift;

    my $ids = $self->get_column('id')->as_query;

    return $self->result_source->schema->resultset('ArticleUnit')
      ->search( { $self->me('article') => { -in => $ids } } );
}

1;
