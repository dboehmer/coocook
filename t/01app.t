use Test2::V0;

use lib 't/lib';
use Test::Coocook;

plan(11);

my $t = Test::Coocook->new( config => { enable_user_registration => 1 }, max_redirect => 0 );

my @POSSIBLE_AUTHZ_ATTRS = (
    'RequiresCapability',    # = see ActionRole::RequiresCapability
    'Public',                # = no permission required
    'CustomAuthz',           # = action is not public but does authorization in code
                             #   TODO this could be tested:
                             #   store flag, make require_capability() remove flag,
                             #   run action, check that flag has been removed
);

subtest "attributes of controller actions" => sub {
    my $app = $t->catalyst_app;

    for ( $app->controllers ) {
        my $controller = $app->controller($_);

        for my $action ( $controller->get_action_methods ) {
            my $action_pkg_name = $action->package_name . "::" . $action->name . "()";
            $action_pkg_name =~ s/^Coocook:://;    # shorten pkg name in output

            if ( $action->name eq 'end' ) {
                note "Skipping $action_pkg_name: is 'end' action";
                next;
            }

            my %attrs = do {
                my @attrs = @{ $action->attributes };
                s/ \( .+ $ //x for @attrs;    # remove arguments in parenthesis, e.g. RequiresCapability(foo)
                map { $_ => 1 } @attrs;
            };

            my $methods = join '+', grep { m/^( DELETE | GET | HEAD | POST | PUT)$/x } sort keys %attrs;

            if ( $attrs{AnyMethod} ) {        # special keyword indicating any method will be ok
                $methods .= '+' if length $methods;
                $methods .= 'any';
            }

            if ( $attrs{CaptureArgs} ) { # actions with CaptureArgs are chain elements and automatically private
                is $methods => '', "$action_pkg_name: action with 'CaptureArgs' has no methods";
                next;
            }

            if ( $attrs{Private} ) {
                $action->name =~ m/^_/    # no output for Catalyst's internal methods
                  or note "Skipping $action_pkg_name: has 'Private' attribute";

                next;
            }

            ok(
                ( $methods eq 'any' or $methods eq 'GET+HEAD' or $methods eq 'POST' ),
                "$action_pkg_name has 'AnyMethod' or is GET & HEAD or POST"
            ) or note "HTTP methods: " . $methods;

            my @used_authz_attrs = grep { $attrs{$_} } @POSSIBLE_AUTHZ_ATTRS;

            is
              @used_authz_attrs => 1,
              "$action_pkg_name has 1 authorization attribute out of: @POSSIBLE_AUTHZ_ATTRS"
              or diag "       found: @used_authz_attrs";
        }
    }
};

subtest "GET http://... redirects to HTTPS" => sub {
    $t->redirect_is(
        'http://localhost/' => 'https://localhost/',
        301    # moved permanently
    );

    $t->redirect_is(
        'http://localhost/path_doesnt_exist' => 'https://localhost/path_doesnt_exist',
        301    # moved permanently
    );
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
    $t->robots_flags_ok( { archive => 1, index => 1 } );

    subtest "404 pages" => sub {
        $t->get('/doesnt_exist');
        $t->status_is(404);
        $t->robots_flags_ok( { archive => 0, index => 0 } );
    };

    subtest "bad request pages" => sub {
        my $guard = $t->local_config_guard( enable_user_registration => 1 );

        $t->get_ok('/register');
        $t->submit_form_fails( { with_fields => { username => '' } }, "submit form" );
        $t->robots_flags_ok( { archive => 0, index => 0 } );
    };

    subtest "internal server error" => sub {
        ok $t->get('/internal_server_error'), "GET /internal_server_error";
        $t->status_is(404);

        no warnings 'once';
        $Coocook::Controller::Error::ENABLE_INTERNAL_SERVER_ERROR_PAGE = 1;

        $t->get_ok('/internal_server_error');
        $t->status_is(200);
        $t->robots_flags_ok( { archive => 0, index => 0 } );
    };

    $t->get_ok('/user/john_doe');
    $t->robots_flags_ok( { archive => 0, index => 1 } );

    subtest "under simulation of fatal mistake in permission" => sub {
        $t->get('/project/2/Other-Project');
        $t->status_is(302);    # actually the login page

        note "manipulating Model::Authorization ...";
        no warnings qw< once redefine >;
        ok local *Coocook::Model::Authorization::has_capability = sub { 1 },    # everything allowed
          "install simulation";

        $t->reload_ok();
        $t->status_is(200);                                                     # not the login page

        $t->robots_flags_ok( { archive => 0, index => 0 } );
    };

    $t->max_redirect(1);

    $t->login_ok( 'john_doe', 'P@ssw0rd' );
    $t->get_ok('/');
    $t->robots_flags_ok( { archive => 0, index => 0 } );
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
    $t->content_lacks('<link.+icon');

    $t->reload_config(
        icon_url  => 'alpha.ico',
        icon_type => 'image/x-icon',
        icon_urls => {
            ''      => 'beta.png',
            '72x72' => '72.png',
        },
    );
    $t->reload_ok();
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

$t->max_redirect(0);

subtest "simply check GET for all endpoints" => sub {    # TODO could we autogenerate the URL list?
    $t->get_ok('/');
    $t->get_ok('/about');
    $t->get_ok('/admin');
    $t->get_ok('/admin/faq');
    $t->get_ok('/admin/faq/1');
    $t->get_ok('/admin/faq/new');
    $t->get_ok('/admin/organizations');
    $t->get_ok('/admin/projects');
    $t->get_ok('/admin/terms');
    $t->get_ok('/admin/terms/2');
    $t->get_ok('/admin/terms/new');
    $t->get_ok('/admin/user/other');
    $t->get_ok('/admin/users');
    $t->get_ok('/badge/dishes_served.svg');
    $t->get_ok('/faq');
    $t->get_ok('/internal_server_error');
    $t->get_ok('/organization/TestData');
    $t->get_ok('/organization/TestData/members');
    $t->get_ok('/projects');
    $t->get_ok('/project/1/Test-Project');
    $t->get_ok('/project/1/Test-Project/article/1');
    $t->get_ok('/project/1/Test-Project/articles');
    $t->get_ok('/project/1/Test-Project/articles/new');
    $t->get_ok('/project/1/Test-Project/dish/1');
    $t->get_ok('/project/1/Test-Project/edit');
    $t->get_ok('/project/1/Test-Project/import');
    $t->get_ok('/project/1/Test-Project/items/unassigned');
    $t->get_ok('/project/1/Test-Project/permissions');
    $t->get_ok('/project/1/Test-Project/print');
    $t->get_ok('/project/1/Test-Project/print/day/2000/1/1');
    $t->get_ok('/project/1/Test-Project/print/project');
    $t->get_ok('/project/1/Test-Project/print/purchase_list/1');
    $t->get_ok('/project/1/Test-Project/purchase_list/1');
    $t->get_ok('/project/1/Test-Project/purchase_lists');
    $t->get_ok('/project/1/Test-Project/quantities');
    $t->get_ok('/project/1/Test-Project/recipe/1');
    $t->get_ok('/project/1/Test-Project/recipes');
    $t->get_ok('/project/1/Test-Project/recipes/import');
    $t->get_ok('/project/1/Test-Project/recipes/import/2');
    $t->get_ok('/project/1/Test-Project/recipes/new');
    $t->get_ok('/project/1/Test-Project/settings');
    $t->get_ok('/project/1/Test-Project/shop_sections');
    $t->get_ok('/project/1/Test-Project/tag/1');
    $t->get_ok('/project/1/Test-Project/tag_group/1');
    $t->get_ok('/project/1/Test-Project/tag_groups');
    $t->get_ok('/project/1/Test-Project/tag_groups/new');
    $t->get_ok('/project/1/Test-Project/tags');
    $t->get_ok('/project/1/Test-Project/tags/new');
    $t->get_ok('/project/1/Test-Project/unit/1');
    $t->get_ok('/project/1/Test-Project/units');
    $t->get_ok('/project/1/Test-Project/units/new');
    $t->get_ok('/recipe/1/pizza');
    $t->get_ok('/recipe/1/pizza/import');
    $t->get_ok('/recipes');
    $t->get_ok('/recover');
    $t->redirect_is( '/settings' => 'https://localhost/settings/account', 302 );
    $t->get_ok('/settings/account');
    $t->get_ok('/settings/organizations');
    $t->get_ok('/settings/projects');
    $t->get_ok('/statistics');
    $t->redirect_is( '/terms' => 'https://localhost/terms/1', 302 );
    $t->get_ok('/terms/1');
    $t->get_ok('/user/john_doe');
};
