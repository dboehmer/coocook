use strict;
use warnings;

use lib 't/lib';

use Test::Coocook;
use Test::Most tests => 79;
use Time::HiRes 'time';

my $t = Test::Coocook->new( test_data => 0 );

my $schema = $t->schema;

$schema->resultset('BlacklistEmail')
  ->add_email( my $blacklist_email = 'blacklisted@example.com', comment => __FILE__ );

$schema->resultset('BlacklistUsername')
  ->add_username( my $blacklist_username = 'blacklisted', comment => __FILE__ );

# normally an organization needs an owner
# but then we couldn't test all the error cases in one block ...
# so we trick a little
my $organization = $schema->fk_checks_off_do(
    sub {
        return $schema->resultset('Organization')->create(
            {
                name           => "TestOrganization",
                display_name   => "Test Organization",
                description_md => __FILE__,
                owner_id       => 9999,
            }
        );
    }
);

$t->get_ok('/');

$t->text_contains("first user");

$t->content_contains('noindex');

{
    my %userdata_ok = (
        username  => 'test',
        email     => 'test@example.com',
        password  => 's3cr3t',
        password2 => 's3cr3t',
    );

    $t->register_fails_like( { %userdata_ok, password2 => 'something-else' }, qr/match/ );

    $t->register_fails_like( { %userdata_ok, email => $blacklist_email },
        qr/e-mail address is invalid or already taken/ );

    $t->register_fails_like(
        { %userdata_ok, email => uc $blacklist_email },
        qr/e-mail address is invalid or already taken/,
        "blacklisted e-mail in uppercase"
    );

    $t->register_fails_like( { %userdata_ok, username => $blacklist_username },
        qr/username is not available/ );

    $t->register_fails_like(
        { %userdata_ok, username => uc $blacklist_username },
        qr/username is not available/,
        "blacklisted username in uppercase"
    );

    $t->register_fails_like(
        { %userdata_ok, username => $organization->name },
        qr/username is not available/,
        "organization name"
    );

    $t->register_fails_like(
        { %userdata_ok, username => uc $organization->name },
        qr/username is not available/,
        "organization name in uppercase"
    );

    $t->register_ok( \%userdata_ok );
}

for my $user1 ( $schema->resultset('User')->find( { name => 'test' } ) ) {
    ok $user1->has_any_role('site_owner'),       "1st user created has 'site_owner' role";
    ok $user1->has_any_role('private_projects'), "1st user created has 'private_projects' role";
}

subtest "verify e-mail address" => sub {
    $t->verify_email_ok();

    $t->title_like( qr/sign in/i, "got redirected to login page" );

    # TODO replace evil HTML "parser" hackery by reasonable HTML parser
    $t->content_like( qr/ <input [^<>]+ name="username" [^<>]+ value="test" /x,
        "username is prefilled in login form" )
      or note $t->uri, $t->content;
};

$t->clear_emails();

$t->content_lacks('Sign up');

$t->reload_config( enable_user_registration => 1 );

$t->get('/');

$t->register_ok(
    {
        username  => 'test2',
        email     => 'test2@example.com',
        password  => 's3cr3t',
        password2 => 's3cr3t',
    }
);

# TODO Test::Cooocook warns that 2 e-mails are stored but that is correct
$t->email_like(qr/Hi test2/);
$t->email_like(qr/Please verify/);
$t->shift_emails();

$t->email_like(qr/Hi test\b/);
$t->email_like(qr/somebody registered/);
$t->email_like(qr/test2/);
$t->email_like(qr/example\.com/);      # contains domain part of e-mail address
$t->email_unlike(qr/test2.+example.+com/);
$t->email_like(qr{ /user/test2 }x);    # URLs to user info pages
$t->email_like(qr{ /admin/user/test2 }x);
$t->shift_emails();

for my $user2 ( $schema->resultset('User')->find( { name => 'test2' } ) ) {
    ok !$user2->has_any_role('site_owner'), "2nd user created hasn't 'site_owner' role";
    ok $user2->has_any_role('private_projects'), "2nd user created has 'private_projects' role";
}

$t->register_fails_like(
    { username => 'new_user', email => 'TEST2@example.com' },
    qr/e-mail address is invalid or already taken/,
    "registration of existing e-mail address (in uppercase) fails"
);

$t->register_fails_like(
    { username => 'TEST2' },
    qr/username is not available/,
    "registration of existing username (in uppercase) fails"
);

$t->register_fails_like(
    { username => 'foobar ' },    # note space char
    qr/username must not contain/,
    "registration with invalid existing username fails"
);

$t->login_fails( 'test', 'invalid' );    # wrong password

$t->login_fails( 'test2', 's3cr3t' );    # not verified

{
    my $t1 = time();
    $t->login_ok( 'test', 's3cr3t' );
    my $t2 = time();

    cmp_ok $t2 - $t1, '>', 1, "login request took more than 1 second";
}

$t->follow_link_ok( { text => 'settings Settings' } );

$t->submit_form_ok(
    {
        with_fields => {
            current_password => 's3cr3t',
            new_password     => 'P@ssw0rd',
            new_password2    => 'P@ssw0rd',
        },
    },
    "submit change password form"
);

$t->text_contains('Your password has been changed');

$t->email_like(qr/ password .+ changed /x);

$t->clear_emails;

$t->change_display_name_ok('John Doe');

$t->logout_ok();

$t->get_ok('/login');

$t->robots_flags_ok( { index => 1, archive => 1 }, "plain /login may be indexed" );

$t->content_unlike( qr/ name="username" .+ value="test" /x,
    "... username is deleted from session cookie by logout" );

$t->content_unlike( qr/ name="store_username" .+ checked /x,
    '... checkbox "store username" is NOT checked' );

$t->get_ok('/login?username=from_query');

$t->robots_flags_ok( { index => 0, archive => 0 }, "/login with query string may NOT be indexed" );

$t->content_like( qr/ name="username" .+ value="from_query" /x,
    "... username is prefilled from URL query" );

$t->content_unlike( qr/ name="store_username" .+ checked /x,
    '... checkbox "store username" is NOT checked' );

is $t->cookie_jar->get_cookies( $t->base, 'username' ) => undef,
  "username is not stored in persistent cookie";

$t->login_ok( 'test', 'P@ssw0rd', store_username => 'on' );

$t->logout_ok();

{
    my $original_length = length $t->cookie_jar->as_string;

    $t->cookie_jar->clear( 'localhost.local', '/', 'coocook_session' )
      and note "deleted session cookie";

    $original_length > length $t->cookie_jar->as_string
      or die "failed to delete session cookie";
}

$t->get_ok('/login');

is $t->cookie_jar->get_cookies( $t->base, 'username' ) => 'test',
  "'username' cookie contains username 'test'";

$t->content_like( qr/ name="username" .+ value="test" /x,
    "username is prefilled from persistent cookie" )
  or diag $t->content;

$t->robots_flags_ok( { index => 0, archive => 0 },
    "/login with username from cookie may NOT be indexed" );

$t->content_like( qr/ name="store_username" .+ checked /x, 'checkbox "store username" is checked' );

$t->login_ok( 'test', 'P@ssw0rd', store_username => '' );

$t->logout_ok();

is $t->cookie_jar->get_cookies( $t->base, 'username' ) => undef,
  "... username was deleted from persistent cookie";

subtest "expired password reset token URL" => sub {
    $t->request_recovery_link_ok('test@example.com');

    $schema->resultset('User')->update( { token_expires => '2000-01-01 00:00:00' } );

    $t->get_email_link_ok(qr/http\S+reset_password\S+/);

    $t->content_like(qr/expired/);

    $t->clear_emails();
};

subtest "password recovery" => sub {
    my $user         = $t->schema->resultset('User')->find( { email_fc => 'test@example.com' } );
    my $new_password = 'new, nice & shiny';

    ok !$user->check_password($new_password), "password is different before";

    $t->request_recovery_link_ok('test@example.com');
    $t->submit_form_ok( { with_fields => { map { $_ => $new_password } 'password', 'password2' } },
        "submit password reset form" );

    $user->discard_changes();
    ok $user->check_password($new_password), "password has been changed";

    $t->logout_ok();

    $t->clear_emails();
};

subtest "password recovery marks e-mail address verified" => sub {
    my $test2        = $schema->resultset('User')->find( { name => 'test2' } );
    my $new_password = 'sUpEr s3cUr3';

    is $test2->email_verified => undef,
      "email_verified IS NULL";

    $t->request_recovery_link_ok('test2@example.com');
    $t->submit_form_ok( { with_fields => { map { $_ => 'sUpEr s3cUr3' } 'password', 'password2' } },
        "submit password reset form" );

    $test2->discard_changes;
    isnt $test2->email_verified => undef,
      "email_verified IS NOT NULL";

    $t->logout_ok();
};

$t->login_ok( 'test', 'new, nice & shiny' );

subtest "redirects after login/logout" => sub {
    $t->get_ok('/about');

    $t->logout_ok();

    $t->base_is( 'https://localhost/about', "client is redirected to last page after logout" );

    # pass link around between login/register
    $t->follow_link_ok( { text => 'Sign up' } );

    # keep link with failed login attempts
    $t->login_fails( 'test', 'invalid' );

    note "uri: " . $t->uri;

    $t->login_ok( 'test', 'new, nice & shiny' );

    $t->base_is( 'https://localhost/about', "client is redirected to last page after login" );
};

subtest "refreshing login page after logging in other browser tab" => sub {
    $t->get_ok('/login?redirect=/statistics');

    $t->base_is( 'https://localhost/statistics', "client is redirected immediately" );
};

subtest "refreshing register page after logging in other browser tab" => sub {
    $t->get_ok('/register?redirect=/statistics');

    $t->base_is( 'https://localhost/statistics', "client is redirected immediately" );
};

subtest "malicious redirects are filtered on logout" => sub {
    $t->is_logged_in();

    $t->post('/logout?redirect=https://malicious.example/');
    $t->base_is( 'https://localhost/', "client is redirected to /" );

    $t->is_logged_out("... but client is logged out anyway");
};

subtest "malicious redirects are filtered on login" => sub {
    $t->post(
        '/login?redirect=https://malicious.example/',
        { username => 'test', password => 'new, nice & shiny' }
    );
    $t->base_is( 'https://localhost/', "client is redirected to /" );
    $t->is_logged_in();

    $t->logout_ok();
    $t->post(
        '/login',
        {
            redirect => 'https://malicious.example/',
            username => 'test',
            password => 'new, nice & shiny'
        }
    );
    $t->base_is( 'https://localhost/', "client is redirected to /" );
    $t->is_logged_in("... but client is logged in anyway");
};

$t->create_project_ok( { name => "Test Project 1" } );

$t->base_unlike( qr/import/, "not redirected to importer for first project" );

note "remove all roles from user";
$schema->resultset('RoleUser')->search( { user_id => '1' } )->delete;

$t->create_project_ok( { name => "Test Project 2" } );

$t->base_like( qr/import/, "redirected to importer" );

$t->content_contains("Test Project 1");

ok my $project = $schema->resultset('Project')->find( { name => "Test Project 1" } ),
  "project is in database";

ok !$project->is_public, "1st project is private";

is $project->owner->name => 'test',
  "new project is owned by new user";

is $project->users->one_row->name => 'test',
  "owner relationship is also stored via table 'projects_users'";

ok my $project2 = $schema->resultset('Project')->find( { name => "Test Project 2" } );

ok $project2->is_public, "2nd project is public";
