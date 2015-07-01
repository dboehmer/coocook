package Coocook::Schema::Result::PurchaseList;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("purchase_lists");

__PACKAGE__->add_columns(
    id      => { data_type => 'int', is_auto_increment => 1 },
    project => { data_type => 'int' },
    name    => { data_type => 'text' },
    date    => { data_type => 'date' },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( [qw<project name>] );

__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project' );

__PACKAGE__->has_many(
    items => 'Coocook::Schema::Result::Item',
    'purchase_list'
);

__PACKAGE__->meta->make_immutable;

1;
