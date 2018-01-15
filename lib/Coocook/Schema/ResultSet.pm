package Coocook::Schema::ResultSet;

# ABSTRACT: base class for all ResultSet classes

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
      Helper::ResultSet::Shortcut::HRI
      >
);

__PACKAGE__->meta->make_immutable;

sub exists {
    my ( $self, $search ) = @_;

    # inspired from DBIx::Class::ResultSet::Void but that is low quality and obsolete
    !!$self->search( $search, { rows => 1, select => [ \1 ] } )->single;
}

1;
