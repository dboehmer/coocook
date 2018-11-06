package Coocook::Schema::ResultSet;

# ABSTRACT: base class for all ResultSet classes

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::NonMoose;
use Carp;

extends 'DBIx::Class::ResultSet';

__PACKAGE__->load_components(
    qw<
      +Coocook::Schema::Component::ProxyMethods
      Helper::ResultSet::CorrelateRelationship
      Helper::ResultSet::IgnoreWantarray
      Helper::ResultSet::Me
      Helper::ResultSet::OneRow
      Helper::ResultSet::Shortcut::HRI
      >
);

# discourage use of first() but don't just die()
# because $c->user() indirectly calls first()
before first => sub {
    carp "You probably want next(), one_row() or single()";
};

__PACKAGE__->meta->make_immutable;

sub exists {
    my $self = shift;

    return !!$self->exists_rs(@_)->single;
}

sub exists_rs {
    my ( $self, $search ) = @_;

    # inspired from DBIx::Class::ResultSet::Void but that is low quality and obsolete
    return $self->search( $search, { rows => 1, select => [ \1 ] } );
}

=head2 only_id_col($id_column_name?)

Returns new resultset with only the column 'id' selected.

=cut

sub only_id_col {
    my ( $self, $id_column_name ) = @_;

    return $self->search( undef, { columns => [ $id_column_name || 'id' ] } );
}

1;
