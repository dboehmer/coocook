package Coocook::Schema;

our $VERSION = 3;    # version of schema definition, not software version!

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'DBIx::Class::Schema::Config';

__PACKAGE__->load_components(
    qw<
      Helper::Schema::QuoteNames
      >
);

__PACKAGE__->meta->make_immutable;

__PACKAGE__->load_namespaces;

1;
