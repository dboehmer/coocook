package Coocook::Model::Schema;

use Moose;

extends 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->meta->make_immutable;

__PACKAGE__->config(
    connect_info => {
        sqlite_unicode => 1,
    },
    schema_class => 'Coocook::Schema',
);

1;
