package Coocook::Plugin::UriForStatic;

# ABSTRACT: Catalyst plugin for static URIs at CDN via $c->uri_for_static()

use Moose::Role;
use Carp;

# TODO support query parameter in config->static_base_uri

before setup_finalize => sub {
    my $c = shift;

    my $base_uri = \$c->config->{static_base_uri};

    if ($$base_uri) {
        $$base_uri =~ s{ / $ }{}x;    # remove trailing slash
    }
};

sub uri_for_static {
    my $c = shift;

    ( ref( $_[0] ) eq '' and $_[0] =~ m{ ^ / [^/] }x )
      or croak "First argument must to uri_for_static must be string with absolute path, not '$_[0]'";

    if ( my $base_uri = $c->config->{static_base_uri} ) {

        # Catalyst->uri_for() as class method returns absolute path without host part
        my $uri = ref($c)->uri_for(@_) || die;

        return $uri->new( $base_uri . $uri );
    }
    else {
        $_[0] = '/static' . $_[0];    # prepend $path with '/static'

        return $c->uri_for(@_);
    }
}

1;
