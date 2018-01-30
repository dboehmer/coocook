#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use TestDB;
use Test::Coocook;
use Test::Most tests => 4;

our $SCHEMA = TestDB->new();

my $t = Test::Coocook->new( max_redirect => 0 );

subtest "HTTP redirects to HTTPS" => sub {
    $t->get('http://localhost/');

    {
        local $TODO = "fix https://github.com/papercreatures/Catalyst-ActionRole-RequireSSL/issues/1";
        $t->status_is(301);    # moved permanently
    }

    $t->header_is( Location => 'https://localhost/' );
};

$t->get_ok('https://localhost');

subtest "HTTP Strict Transport Security" => sub {
    $t->get_ok('https://localhost');
    $t->header_is( 'Strict-Transport-Security' => 'max-age=' . 365 * 24 * 60 * 60, "default" );

    Coocook->setup_finished(0);
    Coocook->config(
        'Plugin::StrictTransportSecurity' => {
            max_age             => 63072000,
            include_sub_domains => 1,
            preload             => 1
        }
    );
    Coocook->setup_finished(1);

    $t->get_ok('https://localhost');
    $t->header_is(
        'Strict-Transport-Security' => 'max-age=63072000; includeSubDomains; preload',
        "with configuration"
    );
};

subtest "public actions are either GET or POST" => sub {
    my $app = $t->catalyst_app;

    for ( $app->controllers ) {
        my $controller = $app->controller($_);

        for my $action ( $controller->get_action_methods ) {
            my %attrs = map { s/\(.+//; $_ => 1 } @{ $action->attributes };

            exists $attrs{Private}
              and next;

            exists $attrs{CaptureArgs}   # actions with CaptureArgs are chain elements and automatically private
              and next;

            exists $attrs{AnyMethod}     # special keyword indicating any method will be ok
              and next;

            $action->name eq 'end'
              and next;

            my $methods = join '+', grep { m/^( DELETE | GET | HEAD | POST | PUT)$/x } sort keys %attrs;
            ok(
                ( $methods eq 'GET+HEAD' or $methods eq 'POST' ),
                $action->package_name . "::" . $action->name . "()"
            ) or note "HTTP methods: " . $methods;
        }
    }
};
