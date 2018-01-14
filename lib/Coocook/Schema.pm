package Coocook::Schema;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use DateTime;

our $VERSION = 8;    # version of schema definition, not software version!

extends 'DBIx::Class::Schema::Config';

__PACKAGE__->load_components(
    qw<
      Helper::Schema::QuoteNames
      >
);

# enable faking connect() by setting our $SCHEMA = ... in test files
around connection => sub {
    my $orig  = shift;
    my $class = shift;

    if ( my $schema = $main::SCHEMA ) {

        # Catalyst::Model::DBIC::Schema composes a schema itself
        # and simply applies the new schema's storage
        if ( ref $class ) {
            my $self = $class;
            $self->storage( $schema->storage );
        }

        return $schema;
    }

    return $class->$orig(@_);
};

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

sub statistics {
    my $self = shift;

    return {
        dishes_served   => $self->resultset('Dish')->count_served,
        public_projects => $self->resultset('Project')->public->count,
        users           => $self->resultset('User')->count,
    };
}

1;
