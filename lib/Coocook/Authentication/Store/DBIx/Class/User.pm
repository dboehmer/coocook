package Coocook::Authentication::Store::DBIx::Class::User;

# ABSTRACT: fixed version of Catalyst::Authentication::Store::DBIx::Class::User

use strict;
use warnings;

use Carp;
use Try::Tiny;

use parent 'Catalyst::Authentication::Store::DBIx::Class::User';

# copied from https://metacpan.org/source/ILMARI/Catalyst-Authentication-Store-DBIx-Class-0.1506/lib%2FCatalyst%2FAuthentication%2FStore%2FDBIx%2FClass%2FUser.pm#L279-296
sub AUTOLOAD {
    my $self = shift;

    ( my $method ) = ( our $AUTOLOAD =~ /([^:]+)$/ );
    return if $method eq "DESTROY";

    return unless ref $self;

    if ( my $code = $self->_user->can($method) ) {
        return $self->_user->$code(@_);
    }
    elsif ( my $accessor = try { $self->_user->result_source->column_info($method)->{accessor} } ) {
        return $self->_user->$accessor(@_);
    }
    else {
        ### CUSTOM CODE HERE ####

        my $package = ref $self->_user;

        # fixes https://github.com/dboehmer/coocook/issues/140
        # resembles Perl default error message
        croak qq(Can't locate object method "$method" via package $package);

        #########################
    }
}

1;
