package Coocook::Model::DB;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->meta->make_immutable;

__PACKAGE__->config(
    connect_info => {
        sqlite_unicode => 1,
    },
    schema_class => 'Coocook::Schema',
);

sub statistics { shift->schema->statistics(@_) }

1;
