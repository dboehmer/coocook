use Test2::V0;

use Time::HiRes 'time';

use lib 't/lib';
use Test::Coocook;

plan(88);

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

$t->robots_flags_ok( { index => 0 } );

{
    my %userdata_ok = (
        username  => 'test',
        email     => 'test@example.com',
        password  => 's3cr3t',
        password2 => 's3cr3t',
    );

    $t->register_fails_like( { %userdata_ok, password2 => 'something-else' },
        qr/match/, "two different passwords" );

    $t->register_fails_like(
        { %userdata_ok, email => $blacklist_email },
        qr/email address is invalid or already taken/,
        "blacklisted email"
    );

    $t->register_fails_like(
        { %userdata_ok, email => uc $blacklist_email },
        qr/email address is invalid or already taken/,
        "blacklisted email in uppercase"
    );

    $t->register_fails_like(
        { %userdata_ok, username => $blacklist_username },
        qr/username is not available/,
        "blacklisted username"
    );

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
    $t->email_count_is(1);

    my $user1 = $schema->resultset('User')->find( { name => 'test' } );

    ok $user1->get_column($_), "column '$_' is set" for 'token_created';
    is $user1->get_column($_) => undef, "column '$_' is NULL" for 'token_expires';

    ok $user1->has_any_role('site_owner'),       "1st user created has 'site_owner' role";
    ok $user1->has_any_role('private_projects'), "1st user created has 'private_projects' role";

    $t->text_lacks( 'Sign up', "registration is not enabled by default" );

    $t->reload_config( enable_user_registration => 1 );
    $t->get('/');

    $t->register_fails_like( \%userdata_ok, qr/username is not available/, "existing username" );

    $t->register_fails_like(
        { %userdata_ok, username => 'TEST' },
        qr/username is not available/,
        "existing username in uppercase"
    );

    $userdata_ok{username} = 'new_user';

    $t->register_fails_like(
        \%userdata_ok,
        qr/email address is invalid or already taken/,
        "existing email address"
    );

    $t->register_fails_like(
        { %userdata_ok, email => uc $userdata_ok{email} },
        qr/email address is invalid or already taken/,
        "existing email address"
    );

    $userdata_ok{email} = 'new_user@example.com';

    $t->schema->txn_begin();
    $user1->update(
        {
            new_email_fc  => $userdata_ok{email},
            token_expires => $user1->format_datetime( DateTime->now->add( hours => 12 ) )
        }
    );

    $t->register_fails_like(
        \%userdata_ok,
        qr/email address is invalid or already taken/,
        "email address that existing user wants to change to"
    );

    note "email change of existing user expires ...";
    $user1->update( { token_expires => $user1->format_datetime_now } );

    $t->register_ok( \%userdata_ok );
    $t->email_count_is(3);

    $t->schema->txn_rollback();
}

subtest "verify email address" => sub {
    $t->get_ok_email_link_like( qr/verify/, "verify email address" );

    # TODO is GET on the link enough? maybe email clients or "security" software will fetch it?
    # - there is no point in requesting the password first
    #   because user needs to be able reset the password via e-mail
    # - maybe display a page with a POST button first?
    # - but every website I know does it with a simple GET

    $t->title_like( qr/sign in/i, "got redirected to login page" );

    $t->input_has_value( username => 'test', "username is prefilled in login form" );
};

$t->clear_emails();

$t->register_ok(
    {
        username  => 'test2',
        email     => 'test2@example.com',
        password  => 's3cr3t',
        password2 => 's3cr3t',
    }
);

$t->email_count_is(2);

$t->email_like(qr/Hi test2/);
$t->email_like(qr/Please verify/);
$t->shift_emails();

$t->email_like(qr/Hi test\b/);
$t->email_like(qr/somebody registered/i);
$t->email_like(qr/test2/);
$t->email_like(qr/example\.com/);      # contains domain part of email address
$t->email_unlike(qr/test2.+example.+com/);
$t->email_like(qr{ /user/test2 }x);    # URLs to user info pages
$t->email_like(qr{ /admin/user/test2 }x);
$t->shift_emails();

for my $user2 ( $schema->resultset('User')->find( { name => 'test2' } ) ) {
    ok !$user2->has_any_role('site_owner'),      "2nd user created hasn't 'site_owner' role";
    ok $user2->has_any_role('private_projects'), "2nd user created has 'private_projects' role";
}

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

$t->text_contains('logged out');

$t->get_ok('/login');

$t->robots_flags_ok( { index => 1, archive => 1 }, "plain /login may be indexed" );

$t->input_has_value( username => '', "... username is deleted from session cookie by logout" );

$t->checkbox_is_off('store_username');

$t->get_ok('/login?username=from_query');

$t->robots_flags_ok( { index => 0, archive => 0 }, "/login with query string may NOT be indexed" );

$t->input_has_value( username => 'from_query', "... username is prefilled from URL query" );

$t->checkbox_is_off('store_username');

is $t->cookie_jar->get_cookies( $t->base, 'username' ) => undef,
  "username is not stored in persistent cookie";

$t->login_ok( 'test', 'P@ssw0rd', store_username => 'on' );

$t->logout_ok();

{
    my $original_length = length $t->cookie_jar->as_string;

    # we want to clear only that specific cookie
    $t->cookie_jar->clear( 'localhost.local', '/', 'coocook_session' )
      and note "deleted session cookie";

    $original_length > length $t->cookie_jar->as_string
      or die "failed to delete session cookie";
}

$t->get_ok('/login');

is $t->cookie_jar->get_cookies( $t->base, 'username' ) => 'test',
  "'username' cookie contains username 'test'";

$t->input_has_value( username => 'test', "username is prefilled from persistent cookie" );

$t->robots_flags_ok( { index => 0, archive => 0 },
    "/login with username from cookie may NOT be indexed" );

$t->form_number(2);
$t->checkbox_is_on('store_username');

$t->login_ok( 'test', 'P@ssw0rd', store_username => '' );

$t->logout_ok();

is $t->cookie_jar->get_cookies( $t->base, 'username' ) => undef,
  "... username was deleted from persistent cookie";

subtest "expired password reset token URL" => sub {
    $t->request_recovery_link_ok('test@example.com');

    $schema->resultset('User')->update( { token_expires => '2000-01-01 00:00:00' } );

    $t->get_ok_email_link_like(qr/reset_password/);

    $t->text_like(qr/expired/);
    $t->text_lacks('verified');

    $t->clear_emails();
};

subtest "password recovery" => sub {
    my $user         = $t->schema->resultset('User')->find( { email_fc => 'test@example.com' } );
    my $new_password = 'new, nice & shiny';

    ok !$user->check_password($new_password), "password is different before";

    $t->request_recovery_link_ok('test@example.com');

    $t->text_contains('verified');

    $t->submit_form_ok(
        {
            with_fields => {
                password  => 'foo',
                password2 => 'bar',
            }
        },
        "submit two different passwords"
    );

    $t->text_like(qr/don.t match/);

    $user->discard_changes();
    ok !$user->check_password($new_password), "password hasn't been changed";

    $t->submit_form_ok( { with_fields => { map { $_ => $new_password } 'password', 'password2' } },
        "submit new password twice" );

    $t->text_like(qr/ password .+ changed/x);

    $user->discard_changes();
    ok $user->check_password($new_password), "password has been changed";

    $t->logout_ok();

    $t->clear_emails();
};

subtest "password recovery marks email address verified" => sub {
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

$t->text_contains("Test Project 1");

ok my $project = $schema->resultset('Project')->find( { name => "Test Project 1" } ),
  "project is in database";

ok !$project->is_public, "1st project is private";

is $project->owner->name => 'test',
  "new project is owned by new user";

is $project->users->one_row->name => 'test',
  "owner relationship is also stored via table 'projects_users'";

ok my $project2 = $schema->resultset('Project')->find( { name => "Test Project 2" } );

ok $project2->is_public, "2nd project is public";
