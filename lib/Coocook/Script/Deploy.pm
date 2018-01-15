package Coocook::Script::Deploy;

# ABSTRACT: script for database maintance based on App::DH

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'App::DH';

has '+schema' => ( default => 'Coocook::Schema' );

__PACKAGE__->meta->make_immutable;

1;
