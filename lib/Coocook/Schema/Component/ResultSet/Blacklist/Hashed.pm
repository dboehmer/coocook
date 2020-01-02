package Coocook::Schema::Component::ResultSet::Blacklist::Hashed;

# ABSTRACT: blacklist modified to store literal values as hashes

use strict;
use warnings;

use feature 'fc';    # Perl v5.16
use parent 'Coocook::Schema::Component::ResultSet::Blacklist';

use Crypt::Digest::SHA256 qw(sha256_b64);

sub _add_value {
    my $self        = shift;
    my $column_name = shift;
    my $value       = shift;

    return $self->create( { $column_name => sha256_b64($value), @_ } );
}

sub _blacklist_contains_literal {
    my ( $self, $column_name, $value ) = @_;

    return $self->next::method( $column_name, sha256_b64($value) );
}

1;
