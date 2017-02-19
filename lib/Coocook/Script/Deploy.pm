package Coocook::Script::Deploy;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'App::DH';

has '+schema' => ( default => 'Coocook::Schema' );

__PACKAGE__->meta->make_immutable;

1;
