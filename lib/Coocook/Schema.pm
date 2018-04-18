package Coocook::Schema;

# ABSTRACT: DBIx::Class-based SQL database representation

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use DateTime;

our $VERSION = 10;    # version of schema definition, not software version!

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

    $self->disable_fk_checks();
    $cb->();
    $self->enable_fk_checks();    # TODO restore original setting instead of always enable
}

sub enable_fk_checks  { shift->_toggle_fk_checks( 1, @_ ) }
sub disable_fk_checks { shift->_toggle_fk_checks( 0, @_ ) }

sub _toggle_fk_checks {
    my ( $self, $enable ) = @_;

    $self->storage->sqlt_type eq 'SQLite'
      or die "only implemented for SQLite";

    my $sql = 'PRAGMA foreign_keys = ' . ( $enable ? 'ON' : 'OFF' );

    $ENV{DBIC_TRACE}
      and warn "$sql\n";

    $self->storage->dbh_do( sub { $_[1]->do($sql) } );
}

sub statistics {
    my $self = shift;

    return {
        dishes_served   => $self->resultset('Dish')->count_served,
        public_projects => $self->resultset('Project')->public->count,
        users           => $self->resultset('User')->count,
    };
}

1;
