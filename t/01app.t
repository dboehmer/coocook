#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use TestDB;
use Test::Coocook;
use Test::Most tests => 11;

my $t = Test::Coocook->new( config => { enable_user_registration => 1 }, max_redirect => 0 );

subtest "attributes of controller actions" => sub {
    my $app = $t->catalyst_app;

    for ( $app->controllers ) {
        my $controller = $app->controller($_);

        for my $action ( $controller->get_action_methods ) {
            my @attrs = @{ $action->attributes };
            s/ \( .+ $ //x for @attrs;

            my %attrs = map { $_ => 1 } @attrs;

            my $methods = join '+', grep { m/^( DELETE | GET | HEAD | POST | PUT)$/x } sort keys %attrs;

            my $action_pkg_name = $action->package_name . "::" . $action->name . "()";

            if ( exists $attrs{CaptureArgs} )
            {    # actions with CaptureArgs are chain elements and automatically private
                is $methods => '', "$action_pkg_name: action with 'CaptureArgs' has no methods";
                next;
            }

            if ( exists $attrs{Private} ) {
                note "Skipping $action_pkg_name: has 'Private' attribute";
                next;
            }

            if ( $action->name eq 'end' ) {
                note "Skipping $action_pkg_name: is 'end' action";
                next;
            }

            ok(
                ( exists $attrs{Public} xor exists $attrs{RequiresCapability} ),
                "$action_pkg_name has either 'Public' or 'RequiresCapability' attribute"
            );

            if ( exists $attrs{AnyMethod} ) {    # special keyword indicating any method will be ok
                $methods .= '+' if length $methods;
                $methods .= 'any';
            }

            ok(
                ( $methods eq 'any' or $methods eq 'GET+HEAD' or $methods eq 'POST' ),
                "$action_pkg_name has 'AnyMethod' or is GET & HEAD or POST"
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

subtest "POST /xmlrpc.php (GitHub issue #106)" => sub {
    note 'https://github.com/dboehmer/coocook/issues/106';

    ok $t->post($_), "POST $_" for '/xmlrpc.php';
    $t->status_is(404);
};

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

    subtest "404 pages" => sub {
        $t->get('/doesnt_exist');
        $t->status_is(404);
        $t->content_contains('noarchive');
        $t->content_contains('noindex');
    };

    subtest "bad request pages" => sub {
        my $guard = $t->local_config_guard( enable_user_registration => 1 );

        $t->get_ok('/register');
        ok $t->submit_form( with_fields => { username => '' } ), "submit form";
        $t->status_is(400);
        $t->content_contains('noarchive');
        $t->content_contains('noindex');
    };

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

    # no 'redirect' parameter for these paths
    for my $path ( '/', '/login', '/register' ) {
        $t->get_ok($path);
        $t->content_contains(q{href="https://localhost/login"});
        $t->content_contains(q{href="https://localhost/register"});
    }

    # default
    $t->get_ok('/statistics');
    $t->content_contains(q{/login?redirect=%2Fstatistics"});

    # query parameter
    $t->get_ok('/?key=value');
    $t->content_contains(q{/login?redirect=%2F%3Fkey%3Dvalue"});

    # redirect path is passed around between login/redirect
    $t->get_ok('/statistics?key=value');
    $t->follow_link_ok( { text => 'Sign up' } );
    $t->max_redirect(1);
    $t->login_ok( 'john_doe', 'P@ssw0rd' );
    $t->base_is('https://localhost/statistics?key=value');
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

subtest "canonical URLs" => sub {
    $t->get_ok('/');
    $t->content_lacks('canonical');

    my $url_base = 'https://www.coocook.example/coocook/';

    my $guard = $t->local_config_guard( canonical_url_base => $url_base );

    $t->get_ok('/');
    $t->content_contains(qq{<link rel="canonical" href="$url_base">});

    $t->get_ok('/statistics?key=value#anchor');
    $t->content_contains(qq{<link rel="canonical" href="${url_base}statistics">});

    ok $t->get($_), "GET $_", for '/doesnt-exist';
    $t->content_lacks('canonical');
};
