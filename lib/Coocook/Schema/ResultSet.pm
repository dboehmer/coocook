package Coocook::Schema::ResultSet;

# ABSTRACT: base class for all ResultSet classes

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::NonMoose;
use Carp;

our @CARP_NOT;

extends 'DBIx::Class::ResultSet';

__PACKAGE__->load_components(
    qw<
      +Coocook::Schema::Component::ProxyMethods
      Helper::ResultSet::CorrelateRelationship
      Helper::ResultSet::IgnoreWantarray
      Helper::ResultSet::Me
      Helper::ResultSet::OneRow
      Helper::ResultSet::Random
      Helper::ResultSet::SetOperations
      Helper::ResultSet::Shortcut::ResultsExist
      Helper::ResultSet::Shortcut::HRI
      >
);

# discourage use of first(), except for Catalyst::Auth::Store::DBIC (upstream code)
before first => sub {
    if ( my $caller = caller(2) ) {
        return if $caller eq 'Catalyst::Authentication::Store::DBIx::Class::User';
    }

    local @CARP_NOT = 'Class::MOP::Method::Wrapped';

    croak "You probably want next(), one_row() or single()";
};

__PACKAGE__->meta->make_immutable;

# from https://metacpan.org/pod/release/MSTROUT/DBIx-Class-0.08100/lib/DBIx/Class/Manual/Cookbook.pod#SELECT-COUNT(DISTINCT-colname)
sub count_distinct {
    my ( $self, $column ) = @_;

    return $self->search( undef, { columns => { count => { COUNT => { DISTINCT => $column } } } } )
      ->hri->one_row->{count};
}

=head2 only_id_col($id_column_name?)

Returns new resultset with only the column 'id' selected.

=cut

sub only_id_col {
    my ( $self, $id_column_name ) = @_;

    return $self->search( undef, { columns => [ $id_column_name || 'id' ] } );
}

sub assert_no_sth {
    my $self = shift;

    # Check if DBIx::Class::Storage::DBI::Cursor already has a statement handle
    defined( $self->cursor->{sth} ) and croak "Statement already running";
}

1;
