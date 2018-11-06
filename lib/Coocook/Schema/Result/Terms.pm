package Coocook::Schema::Result::Terms;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use Carp;
use DateTime;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('terms');

__PACKAGE__->add_columns(
    id         => { data_type => 'int', is_auto_increment => 1 },
    valid_from => { data_type => 'date' },
    content_md => { data_type => 'text' },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( ['valid_from'] );

__PACKAGE__->has_many( terms_users => 'Coocook::Schema::Result::TermsUser' );
__PACKAGE__->many_to_many( users => terms_users => 'user' );

__PACKAGE__->meta->make_immutable;

=head2 cmp_validity_today

Returns C<-1>/C<0>/C<+1> similar to Perl's C<< <=> >> operator when comparing with
C<< DateTime->today >>.

=cut

our $CMP_VALID_IN_PAST   = -1;
our $CMP_VALID_TODAY     = 0;
our $CMP_VALID_IN_FUTURE = +1;

sub cmp_validity_today {
    my $self = shift;

    my $cmp = ( $self->valid_from <=> DateTime->today );

    if ( $cmp < 0 ) {    # valid_from is in the past
        my $next_until_today_rs =
          $self->neighbors(+1)->search( { valid_from => { '<=' => DateTime->today->ymd } } );

        return $next_until_today_rs->exists ? $CMP_VALID_IN_PAST : $CMP_VALID_TODAY;
    }
    elsif ( $cmp == 0 ) { return $CMP_VALID_TODAY }
    else                { return $CMP_VALID_IN_FUTURE }
}

=head2 reasons_to_freeze

Returns a list of reasons why this row can not be edited.

=cut

sub reasons_to_freeze {
    my $self = shift;

    if    ( $self->valid_from <= DateTime->today ) { return 'not_in_future' }
    elsif ( $self->terms_users->exists )           { return 'has_users' }
    else                                           { return () }
}

=head2 reasons_to_keep

Returns a list of reasons why this row can not be deleted.
The list is empty if the row can be deleted.
The list is definitely not empty if the row can't be deleted but might be incomplete.

=cut

sub reasons_to_keep {
    my $self = shift;

    return 'has_users'
      if $self->terms_users->exists;

    my $cmp = $self->cmp_validity_today;

    if ( $cmp == $CMP_VALID_IN_PAST ) {
        return $self->neighbors(-1)->exists ? 'has_previous' : ();
    }
    elsif ( $cmp == $CMP_VALID_TODAY ) {
        return 'is_currently_valid';
    }
    elsif ( $cmp == $CMP_VALID_IN_FUTURE ) {
        return $self->neighbors(+1)->exists ? 'has_next' : ();
    }
    else { die "code broken" }
}

=head2 next($offset?)

Returns next valid terms. C<$offset> is +1 by default.

=cut

sub next { shift->neighbor( shift || 1 ) }

=head2 previous($offset?)

Returns previous valid terms. C<$offset> might be positive or negative and is -1 by default.

=cut

sub previous { shift->neighbor( -1 * abs( shift || 1 ) ) }

=encoding utf8

=head2 neighbor(±$offset)

Returns terms valid C<$offset> elements before/after the current object.
Negative C<$offset> means previous terms.
Positive C<$offset> means next terms.

=cut

sub neighbor {
    my ( $self, $offset ) = @_;

    return $self->neighbors($offset)->order($offset)->search( undef, { offset => abs($offset) - 1 } )
      ->one_row;
}

=head2 neighbors(±1)

Returns a C<ResultSet::Terms> with all terms valid before/after the current object
depending on argument C<$direction> being negative/positive respectively.

    my $terms_valid_before_rs = $terms_row->neighbors(-1);
    my $terms_valid_after_rs  = $terms_row->neighbors(+1);

=cut

sub neighbors {
    my ( $self, $direction ) = @_;

    defined $direction
      or croak "direction must be defined";

    $direction != 0
      or croak "direction must not be zero";

    return $self->result_source->resultset->search(
        {
            valid_from => { ( $direction < 0 ? '<' : '>' ) => $self->get_column('valid_from') },
        }
    );
}

1;
