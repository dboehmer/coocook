package Coocook::Schema::DeploymentHandler;

use Moose;

extends 'App::DH';

has '+schema' => ( default => 'Coocook::Schema' );

__PACKAGE__->meta->make_immutable;

1;
