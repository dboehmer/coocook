package Coocook::Schema;

# ABSTRACT: DBIx::Class-based SQL database representation

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use DateTime;
use DBIx::Class::Helpers::Util qw< normalize_connect_info >;

our $VERSION = 20;    # version of schema definition, not software version!

extends 'DBIx::Class::Schema::Config';

__PACKAGE__->load_components(
    qw<
      Helper::Schema::QuoteNames
      >
);

__PACKAGE__->meta->make_immutable;

__PACKAGE__->load_namespaces( default_resultset_class => '+Coocook::Schema::ResultSet' );

=head2 connection

Overrides original C<connection> in order to set sane default values.

=over 4

=item * enable C<foreign_keys> pragma in SQLite

=back

=cut

sub connection {
    my $self = shift;

    my $args = normalize_connect_info(@_);

    my $on_connect_do = \$args->{on_connect_do};

    my $enable_fk = sub {
        my $storage = shift;

        if ( $storage->sqlt_type eq 'SQLite' ) {
            return ['PRAGMA foreign_keys = 1'];
        }
        else {
            return;
        }
    };

    if ( not defined $$on_connect_do ) {
        $$on_connect_do = [$enable_fk];
    }
    elsif ( ref $$on_connect_do eq 'ARRAY' ) {
        push @$$on_connect_do, $enable_fk;
    }
    elsif ( ref $$on_connect_do eq 'CODE' ) {
        my $coderef = $$on_connect_do;

        $$on_connect_do = [
            sub { $coderef->(); return () },    # ignore return value
            $enable_fk,
        ];
    }
    else {                                      # scalar
        $$on_connect_do = [ $$on_connect_do, $enable_fk ];
    }

    return $self->next::method(@_);
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

sub fk_checks_off_do {
    my $self = shift;
    my $cb   = shift;

    my $original_state = $self->sqlite_pragma('foreign_keys');

    $original_state
      and $self->disable_fk_checks();

    $cb->(@_);

    $original_state
      and $self->enable_fk_checks();
}

sub enable_fk_checks  { shift->sqlite_pragma( foreign_keys => 1 ) }
sub disable_fk_checks { shift->sqlite_pragma( foreign_keys => 0 ) }

sub sqlite_pragma {
    my ( $self, $pragma, $set_value ) = @_;

    $self->storage->sqlt_type eq 'SQLite'
      or die "only implemented for SQLite";

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

sub statistics {
    my $self = shift;

    return {
        dishes_served   => $self->resultset('Dish')->in_past_or_today->sum_servings,
        dishes_planned  => $self->resultset('Dish')->in_future->sum_servings,
        recipes         => $self->resultset('Recipe')->count_distinct('name'),
        public_projects => $self->resultset('Project')->public->count,
        users           => $self->resultset('User')->count,
        groups          => $self->resultset('Group')->count,
    };
}

1;
