package Coocook::Schema::Component::ResultSet::Blacklist;

use strict;
use warnings;

use feature 'fc';    # Perl v5.16

use Crypt::Digest::SHA256 qw(sha256_b64);

# ABSTRACT: common methods for blacklist tables

=head1 METHODS

=head2 _is_value_ok($column_name, $value)

Returns boolish value. True means the value is B<not> blacklisted.

=cut

sub _blacklist_default_type { 'cleartext' }

sub _add_value {
    my $self  = shift;
    my $value = fc(shift);

    my $type      = $self->_blacklist_default_type;
    my $type_col  = $self->_blacklist_type_column;
    my $value_col = $self->_blacklist_value_column;

    if ( $type eq 'sha256_b64' ) {
        $value = sha256_b64($value);
    }
    else {
        $type eq 'cleartext'
          or $type eq 'wildcard'
          or die "Unsupported type '$type'";
    }

    return $self->create( { $value_col => $value, $type_col => $type, @_ } );
}

sub _is_value_ok {
    my ( $self, $value ) = @_;

    $value = fc $value;

    my $blacklist = $self->hri;

    my $type_col  = $self->_blacklist_type_column;
    my $value_col = $self->_blacklist_value_column;

    $self->results_exist( { $type_col => 'cleartext', $value_col => $value } )
      and return '';

    $self->results_exist( { $type_col => 'sha256_b64', $value_col => sha256_b64($value) } )
      and return '';

    {
        my $wildcards = $self->search( { $type_col => 'wildcard' } )->get_column($value_col);

        while ( my $wildcard = $wildcards->next ) {
            $wildcard =~ s/\*/.*/g;    # convert to regexp

            $value =~ m/ ^ $wildcard $ /x
              and return '';
        }
    }

    return 1;    # nothing matched -> value is ok
}

1;
