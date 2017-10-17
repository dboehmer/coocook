package Coocook::Schema;

our $VERSION = 7;    # version of schema definition, not software version!

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'DBIx::Class::Schema::Config';

__PACKAGE__->load_components(
    qw<
      Helper::Schema::QuoteNames
      >
);

__PACKAGE__->meta->make_immutable;

__PACKAGE__->load_namespaces( default_resultset_class => '+Coocook::Schema::ResultSet' );

=head2 count(@resultsets?)

Returns accumulated number of rows in @resultsets. Defaults to all resultsets.

=cut

sub count {
    my $self = shift;

    my $records = 0;
    $records += $self->resultset($_)->count for @_ ? @_ : $self->sources;
    return $records;
}

sub fk_checks_off_do {
    my ( $self, $cb ) = @_;

    $self->storage->sqlt_type eq 'SQLite'
      or die "only implemented for SQLite";

    $self->storage->dbh_do( sub { $_[1]->do('PRAGMA foreign_keys = OFF;') } );
    $cb->();
    $self->storage->dbh_do( sub { $_[1]->do('PRAGMA foreign_keys = ON;') } );
}

1;
