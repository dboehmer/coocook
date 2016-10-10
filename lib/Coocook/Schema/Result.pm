package Coocook::Schema::Result;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::NonMoose;

extends 'DBIx::Class::Core';

__PACKAGE__->load_components(
    qw<
      InflateColumn::DateTime
      +Coocook::Schema::Component::Result::Boolify
      >
);

__PACKAGE__->meta->make_immutable;

1;
