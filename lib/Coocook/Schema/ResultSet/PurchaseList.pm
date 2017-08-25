package Coocook::Schema::ResultSet::PurchaseList;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::SortByName');
sub sorted_by_columns { 'date', 'name' }

__PACKAGE__->meta->make_immutable;

# retrieves all items from all selected lists
sub items {
    my $self = shift;

    my $ids = $self->get_column('id')->as_query;

    return $self->result_source->schema->resultset('Item')
      ->search( { $self->me('purchase_list') => { -in => $ids } } );
}

1;
