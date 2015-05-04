package Coocook::Schema;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'DBIx::Class::Schema';

__PACKAGE__->meta->make_immutable;

__PACKAGE__->load_namespaces;

1;
