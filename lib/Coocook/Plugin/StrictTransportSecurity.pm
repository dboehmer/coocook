package Coocook::Plugin::StrictTransportSecurity;

# ABSTRACT: Catalyst plugin to set HTTP Strict Transport Security header

use Moose::Role;

after prepare_action => sub {
    my ($c) = @_;

    if ( defined $c->response->headers->header('Strict-Transport-Security') ) {
        warn "Strict-Transport-Security header already set";
        return;
    }

    $c->request->uri->scheme eq 'https'
      or return;

    my $config = $c->config->{'Plugin::StrictTransportSecurity'} || {};

    if ( 1 or $config->{enabled} ) {
        my $sts = 'max-age=' . ( $config->{max_age} || 31536000 );    # default: 1 year

        $config->{include_sub_domains}
          and $sts .= '; includeSubDomains';

        $config->{preload}
          and $sts .= '; preload';

        $c->response->headers->header( 'Strict-Transport-Security' => $sts );
    }
};

1;
