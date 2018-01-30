package Coocook::Plugin::StrictTransportSecurity;

# ABSTRACT: Catalyst plugin to set HTTP Strict Transport Security header

use Moose::Role;

after prepare_action => sub {
    my ($c) = @_;

    my $config = $c->config->{'Plugin::StrictTransportSecurity'} || {};

    if ( $config->{disabled} ) {
        $c->debug and $c->log->info("Plugin::StrictTransportSecurity is disabled by config");
        return;
    }

    if ( defined $c->response->headers->header('Strict-Transport-Security') ) {
        $c->log->warn("Strict-Transport-Security header already set");
        return;
    }

    my $sts = 'max-age=' . ( $config->{max_age} || 31536000 );    # default: 1 year

    $config->{include_sub_domains}
      and $sts .= '; includeSubDomains';

    $config->{preload}
      and $sts .= '; preload';

    if ( $c->request->uri->scheme ne 'https' ) {
        if ( $c->debug ) {
            $c->log->info("Would set HTTP Strict Transport Security header if HTTPS");
            $c->log->debug("Strict-Transport-Security: $sts");
        }

        return;
    }

    $c->response->headers->header( 'Strict-Transport-Security' => $sts );
};

1;
