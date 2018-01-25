#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use TestDB;
use Test::Coocook;
use Test::Most tests => 3;

our $SCHEMA = TestDB->new();

my $t = Test::Coocook->new( max_redirect => 0 );

subtest "HTTP redirects to HTTPS" => sub {
    $t->get('http://localhost/');
    $t->status_is(302);
    $t->header_is( Location => 'https://localhost/' );
};

$t->get_ok('https://localhost');

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
