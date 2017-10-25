package Coocook::Schema::ResultSet;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::NonMoose;

extends 'DBIx::Class::ResultSet';

__PACKAGE__->load_components(
    qw<
      +Coocook::Schema::Component::DateTimeHelper
      Helper::ResultSet::CorrelateRelationship
      Helper::ResultSet::IgnoreWantarray
      Helper::ResultSet::Me
      >
);

__PACKAGE__->meta->make_immutable;

sub inflate_hashes {
    shift->search( undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' } );
}

1;
