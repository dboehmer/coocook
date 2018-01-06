package Coocook::Model::Token;

# ABSTRACT: handle hashed passwords or completely random tokens

use strict;
use warnings;

our $SALT_BYTES         = 16;
our $TOKEN_BYTES        = 16;
our $ARGON2_T_COST      = 3;
our $ARGON2_M_FACTOR    = '32M';
our $ARGON2_PARALLELISM = 1;
our $ARGON2_TAG_SIZE    = 16;

use Crypt::Argon2 qw< argon2i_pass argon2i_verify >;
use MIME::Base64::URLSafe;
use Net::SSLeay;

sub new {
    my $self = shift;

    my $class = ref $self || $self;

    my $token = $self->_random_bytes($TOKEN_BYTES);

    return bless \$token, $class;
}

sub from_string {
    my ( $self, $string ) = @_;

    my $class = ref $self || $self;

    return bless \$string, $class;
}

sub from_base64 {
    my ( $self, $base64 ) = @_;

    return $self->from_string( urlsafe_b64decode($base64) );
}

sub to_base64 {
    my $self = shift;

    return urlsafe_b64encode($$self);
}

sub to_salted_hash {
    my $self = shift;

    my $salt = $self->_random_bytes($SALT_BYTES);

    return argon2i_pass( $$self, $salt, $ARGON2_T_COST, $ARGON2_M_FACTOR, $ARGON2_PARALLELISM,
        $ARGON2_TAG_SIZE );
}

sub verify_salted_hash {
    my ( $self, $hash ) = @_;

    return argon2i_verify( $hash, $$self );
}

sub _random_bytes {
    my ( $self, $bytes ) = @_;

    Net::SSLeay::RAND_bytes( my $random, $bytes )
      or die "Net::SSLeay couldn't deliver $bytes random bytes";

    return $random;
}

1;
