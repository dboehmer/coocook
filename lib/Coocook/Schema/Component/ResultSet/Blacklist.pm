package Coocook::Schema::Component::ResultSet::Blacklist;

use strict;
use warnings;

# ABSTRACT: common methods for blacklist tables

=head1 METHODS

=head2 is_value_ok($column_name, $value)

Returns boolish value. True means the value is B<not> blacklisted.

=cut

sub is_value_ok {
    my ( $self, $column_name, $value ) = @_;

    $self->exists( { $column_name => $value } )
      and return '';    # TODO return () or "false" aka ''?

    my $wildcards = $self->search( { -bool => 'wildcard' } )->get_column($column_name);

    while ( my $wildcard = $wildcards->next ) {
        $wildcard =~ s/\*/.*/g;    # convert to regexp

        $value =~ m/ ^ $wildcard $ /x
          and return '';
    }

    return 1;
}

1;
