package Coocook::Schema::Result::PurchaseList;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('purchase_lists');

__PACKAGE__->add_columns(
    id         => { data_type => 'integer', is_auto_increment => 1 },
    project_id => { data_type => 'integer' },
    name       => { data_type => 'text' },
    date       => { data_type => 'date' },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( [qw<project_id name>] );

__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project', 'project_id' );

__PACKAGE__->has_many(
    items => 'Coocook::Schema::Result::Item',
    'purchase_list_id'
);

__PACKAGE__->many_to_many( articles => items => 'article' );
__PACKAGE__->many_to_many( units    => items => 'unit' );

__PACKAGE__->meta->make_immutable;

1;
