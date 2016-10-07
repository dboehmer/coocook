package Coocook::Schema::ResultSet;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::NonMoose;

extends 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::Me');

__PACKAGE__->meta->make_immutable;

1;
