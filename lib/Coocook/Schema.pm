package Coocook::Schema;

# ABSTRACT: DBIx::Class-based SQL database representation

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use DateTime;

our $VERSION = 13;    # version of schema definition, not software version!

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

    @_ or warn "missing connection information";

    my $extra_attributes = do {
        my $index =
            ( @_ == 1 and ref $_[0] eq 'HASH' ) ? 0
          : ( @_ <= 2 and ref $_[0] eq 'CODE' ) ? 1
          :                                       3;

        $_[$index] //= {};
    };

    my $on_connect_do = \$extra_attributes->{on_connect_do};

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

    return $self->SUPER::connection(@_);
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
        dishes_served   => $self->resultset('Dish')->in_past_or_today->sum_servings,
        dishes_planned  => $self->resultset('Dish')->in_future->sum_servings,
        recipes         => $self->resultset('Recipe')->count_distinct('name'),
        public_projects => $self->resultset('Project')->public->count,
        users           => $self->resultset('User')->count,
    };
}

1;
