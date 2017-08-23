package Coocook::Schema::Result::Project;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("projects");

__PACKAGE__->add_columns(
    id          => { data_type => 'int', is_auto_increment => 1 },
    name        => { data_type => 'text' },
    url_name    => { data_type => 'text' },
    url_name_fc => { data_type => 'text' }, # fold cased
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( ['name'], ['url_name'], ['url_name_fc'] );

__PACKAGE__->has_many( meals => 'Coocook::Schema::Result::Meal' );

__PACKAGE__->has_many( purchase_lists => 'Coocook::Schema::Result::PurchaseList' );

__PACKAGE__->meta->make_immutable;

# TODO add relationship 'articles', remove pseudo-accessor
sub articles {
    my $self = shift;

    return $self->result_source->schema->resultset('Article');
}

1;
