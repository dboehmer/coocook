package Coocook::Schema;

# ABSTRACT: DBIx::Class-based SQL database representation

use Carp;
use Clone;    # indirect dependency required for connection()
use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use DateTime;
use DBIx::Class::Helpers::Util qw< normalize_connect_info >;

our $VERSION = 23;    # version of schema definition, not software version!

extends 'DBIx::Class::Schema::Config';

__PACKAGE__->load_components(
    qw<
      Helper::Schema::QuoteNames
      >
);

__PACKAGE__->meta->make_immutable;

__PACKAGE__->load_namespaces( default_resultset_class => '+Coocook::Schema::ResultSet' );

=head1 Generic Methods

=head2 connection

Overrides original C<connection> in order to set sane default values.

=over 4

=item * enable C<foreign_keys> pragma in SQLite

=back

=cut

# DBIx::Class uses Hash::Merge for merging our $connect_info with other data.
# That module uses Clone::Choose but only with Clone.pm it can do the merge.
# So we need to require Clone.pm
sub connection {
    my $self = shift;

    my $connect_info  = normalize_connect_info(@_);
    my $on_connect_do = \$connect_info->{on_connect_do};

    # identifying the sql_type at connect time is easier than parsing the DSN
    my $enable_fk = sub {
        my $storage = shift;

        $storage->sqlt_type eq 'SQLite'
          and return ['PRAGMA foreign_keys = 1'];

        return;    # required because otherwise returns result '' from 'eq' above
    };

    if ( not defined $$on_connect_do ) {
        $$on_connect_do = [$enable_fk];
    }
    elsif ( ref $$on_connect_do eq 'ARRAY' ) {
        unshift @$$on_connect_do, $enable_fk;
    }
    elsif ( ref $$on_connect_do eq 'CODE' ) {
        my $coderef = $$on_connect_do;    # copy original value
        $$on_connect_do = [
            $enable_fk,                   # $enable_fk first to allow overriding
            sub {
                $coderef->();             # return value of original simple coderef is to be ignored
                return [];
            }
        ];
    }
    else {                                # scalar
        my $scalar = $$on_connect_do;     # copy original value
        $$on_connect_do = [
            $enable_fk,                   # $enable_fk first to allow overriding
            sub { [$scalar] }
        ];
    }

    return $self->next::method($connect_info);
}

=head2 count(@resultsets?)

Returns accumulated number of rows in @resultsets. Defaults to all resultsets.

=cut

sub count {
    my $self = shift;

    my $records = 0;
    $records += $self->resultset($_)->count for @_ ? @_ : $self->sources;
    return $records;
}

sub statistics {
    my $self = shift;

    return {
        dishes_served   => $self->resultset('Dish')->in_past_or_today->sum_servings,
        dishes_planned  => $self->resultset('Dish')->in_future->sum_servings,
        recipes         => $self->resultset('Recipe')->count_distinct('name'),
        public_projects => $self->resultset('Project')->public->count,
        users           => $self->resultset('User')->count,
        organizations   => $self->resultset('Organization')->count,
    };
}

=head1 PostgreSQL-specific Methods

=head2 pgsql_set_constraints_deferred()

Issues `SET CONSTRAINTS ALL DEFERRED` if connected to PostgreSQL.
Otherwise does nothing.

=cut

sub pgsql_set_constraints_deferred {
    my $self = shift;

    if ( $self->storage->sqlt_type eq 'PostgreSQL' ) {
        $self->storage->dbh_do( sub { $_[1]->do('SET CONSTRAINTS ALL DEFERRED') } );
    }
}

=head1 SQLite-specific Methods

=head2 $schema->fk_checks_off_do( sub { ... } )

Runs given coderef with SQLite pragma C<foreign_keys> temporarily turned off.
The original pragma state is then restored.

In case of success the coderef's return value is passed if it is true.
In other cases the return value is undefined.

Probably we should enforce an FK integrity check after the
completion of the (possibly long) subroutine as soon as we
know how to do this.

=cut

sub fk_checks_off_do {
    my $self    = shift;
    my $coderef = shift;

    my $original_state = $self->sqlite_pragma('foreign_keys');

    $original_state
      and $self->disable_fk_checks();

    my $result = $coderef->(@_);

    $original_state
      and $self->enable_fk_checks();

    return $result;
}

sub enable_fk_checks  { shift->sqlite_pragma( foreign_keys => 1 ) }
sub disable_fk_checks { shift->sqlite_pragma( foreign_keys => 0 ) }

sub sqlite_pragma {
    my ( $self, $pragma, $set_value ) = @_;

    $self->storage->sqlt_type eq 'SQLite'
      or croak "sqlite_pragma() works only on SQLite";

    my $sql = "PRAGMA '$pragma'";

    defined $set_value
      and $sql .= " = '$set_value'";

    $ENV{DBIC_TRACE}
      and warn "$sql\n";

    if ( defined $set_value ) {
        return $self->storage->dbh_do( sub { $_[1]->do($sql) } );
    }
    else {
        return $self->storage->dbh_do( sub { return $_[1]->selectrow_array($sql) } );
    }
}

1;
