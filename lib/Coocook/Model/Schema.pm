package Coocook::Model::Schema;

use Moose;

extends 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->meta->make_immutable;

__PACKAGE__->config( schema_class => 'Coocook::Schema', );

1;
