package Coocook::Schema::Component::ResultSet::Blacklist;

use strict;
use warnings;

use feature 'fc';    # Perl v5.16

# ABSTRACT: common methods for blacklist tables

=head1 METHODS

=head2 _is_value_ok($column_name, $value)

Returns boolish value. True means the value is B<not> blacklisted.

=cut

sub _is_value_ok {
    my ( $self, $column_name, $value ) = @_;

    $value = fc $value;

    return not( $self->_blacklist_contains_literal( $column_name, $value )
        or $self->_blacklist_wildcard_matches( $column_name, $value ) );
}

sub _blacklist_contains_literal {
    my ( $self, $column_name, $value ) = @_;

    return $self->exists( { -not_bool => 'wildcards', $column_name => $value } );
}

sub _blacklist_wildcard_matches {
    my ( $self, $column_name, $value ) = @_;

    my $wildcards = $self->search( { -bool => 'wildcard' } )->get_column($column_name);

    while ( my $wildcard = $wildcards->next ) {
        $wildcard =~ s/\*/.*/g;    # convert to regexp

        $value =~ m/ ^ $wildcard $ /x
          and return 1;
    }

    return;
}

1;
