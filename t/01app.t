#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use TestDB;
use Test::Coocook;
use Test::Most tests => 9;

my $t = Test::Coocook->new( max_redirect => 0 );

subtest "public actions are either GET or POST" => sub {
    my $app = $t->catalyst_app;

    for ( $app->controllers ) {
        my $controller = $app->controller($_);

        for my $action ( $controller->get_action_methods ) {
            my @attrs = @{ $action->attributes };
            s/ \( .+ $ //x for @attrs;

            my %attrs = map { $_ => 1 } @attrs;

            my $methods = join '+', grep { m/^( DELETE | GET | HEAD | POST | PUT)$/x } sort keys %attrs;

            exists $attrs{Private}
              and next;

            if ( exists $attrs{CaptureArgs} )
            {    # actions with CaptureArgs are chain elements and automatically private
                $methods eq ''
                  or warn "Chain action "
                  . $action->package_name . "::"
                  . $action->name
                  . " is restricted to HTTP methods "
                  . $methods . "\n";

                next;
            }

            exists $attrs{AnyMethod}    # special keyword indicating any method will be ok
              and next;

            $action->name eq 'end'
              and next;

            ok(
                ( $methods eq 'GET+HEAD' or $methods eq 'POST' ),
                $action->package_name . "::" . $action->name . "()"
            ) or note "HTTP methods: " . $methods;
        }
    }
};

subtest "GET http://... redirects to HTTPS" => sub {
    $t->get('http://localhost/');
    $t->status_is(301);    # moved permanently
    $t->header_is( Location => 'https://localhost/' );

    $t->get('http://localhost/path_doesnt_exist');
    $t->status_is(301);    # moved permanently
    $t->header_is( Location => 'https://localhost/path_doesnt_exist' );
};

subtest "POST http://... is catched as well" => sub {    # TODO define exact behavior
    $t->post('http://localhost/');
    $t->status_like(qr/ ^[34] /x);
};

$t->get_ok('https://localhost');

subtest "HTTP Strict Transport Security" => sub {
    $t->get('http://localhost');
    $t->lacks_header_ok( 'Strict-Transport-Security', "no header for plain HTTP" );

    $t->get_ok('https://localhost');
    $t->header_is( 'Strict-Transport-Security' => 'max-age=' . 365 * 24 * 60 * 60, "default" );

    $t->reload_config(
        'Plugin::StrictTransportSecurity' => {
            max_age             => 63072000,
            include_sub_domains => 1,
            preload             => 1
        }
    );

    $t->get_ok('https://localhost');
    $t->header_is(
        'Strict-Transport-Security' => 'max-age=63072000; includeSubDomains; preload',
        "with configuration"
    );
};

subtest "static URIs" => sub {
    $t->get('/');
    $t->content_contains('https://localhost/static/css/style.css');

    $t->reload_config( static_base_uri => 'https://coocook-cdn.example/' );
    $t->get('/');
    $t->content_contains('https://coocook-cdn.example/css/style.css');
};

subtest "robots meta tag" => sub {
    $t->get_ok('/');
    $t->content_lacks('noarchive');
    $t->content_lacks('noindex');

    $t->get_ok('/user/john_doe');
    $t->content_contains('noarchive');
    $t->content_lacks('noindex');

    subtest "under simulation of fatal mistake in permission" => sub {
        $t->get('/project/Other-project');
        $t->status_is(302);    # actually the login page

        note "manipulating Model::Authorization ...";
        no warnings qw< once redefine >;
        ok local *Coocook::Model::Authorization::has_capability = sub { 1 },    # everything allowed
          "install simulation";

        $t->reload;
        $t->status_is(200);                                                     # not the login page

        $t->content_contains('noarchive');
        $t->content_contains('noindex');
    };

    $t->max_redirect(1);

    $t->login_ok( 'john_doe', 'P@ssw0rd' );
    $t->get_ok('/');
    $t->content_contains('noarchive');
    $t->content_contains('noindex');
};

subtest "Redirect URL parameter" => sub {
    $t->logout_ok();

    # no 'redirect' parameter for '/'
    $t->get_ok('/');
    $t->content_contains(q{/login"});

    # default
    $t->get_ok('/statistics');
    $t->content_contains(q{/login?redirect=statistics"});

    # query parameter
    $t->get_ok('/?key=value');
    $t->content_contains(q{/login?redirect=%2F%3Fkey%3Dvalue"});

    # query parameter 'error' is filtered
    $t->get_ok('/?error=message&key=value');
    local $TODO = "rework messaging system, then implement this if still necessary";
    $t->content_contains(q{/login?redirect=%2F%3Fkey%3Dvalue"});
};

subtest favicons => sub {
    $t->get_ok('/');
    $t->content_lacks('icon');

    $t->reload_config(
        icon_url  => 'alpha.ico',
        icon_type => 'image/x-icon',
        icon_urls => {
            ''      => 'beta.png',
            '72x72' => '72.png',
        },
    );
    $t->reload();
    $t->content_contains(q{<link rel="icon" type="image/x-icon" href="alpha.ico">});
    $t->content_contains(q{<link rel="apple-touch-icon-precomposed"  href="beta.png">});
    $t->content_contains(q{<link rel="apple-touch-icon-precomposed" sizes="72x72" href="72.png">});
};
