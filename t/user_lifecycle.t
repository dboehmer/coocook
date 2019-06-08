use strict;
use warnings;

use lib 't/lib';

use DBICx::TestDatabase;
use Test::Coocook;
use Test::Most tests => 47;
use Time::HiRes 'time';

my $t = Test::Coocook->new( deploy => 0 );

my $schema = $t->schema;

$t->get_ok('/');

$t->register_ok(
    {
        username  => "test",
        email     => "test\@example.com",
        password  => "s3cr3t",
        password2 => "s3cr3t",
    }
);

for my $user1 ( $schema->resultset('User')->find( { name => 'test' } ) ) {
    ok $user1->has_role('site_admin'),       "1st user created has 'site_admin' role";
    ok $user1->has_role('private_projects'), "1st user created has 'private_projects' role";
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

Coocook->reload_config( enable_user_registration => 1 );

$t->get('/');

$t->register_ok(
    {
        username  => "test2",
        email     => "test2\@example.com",
        password  => "s3cr3t",
        password2 => "s3cr3t",
    }
);

$t->shift_emails();
$t->email_like(qr/registered/);
$t->clear_emails();

my $content_after_registration = $t->content;

subtest "registration of existing e-mail address triggers e-mail" => sub {
    $t->register_ok(
        {
            username  => 'test_other',
            email     => 'test2@example.com',
            password  => 's3cr3t',
            password2 => 's3cr3t',
        }
    );

    $t->content_is( $content_after_registration, "content is same as with new e-mail address" );

    $t->email_like(qr/ (try|tried) .+ register /x);

    $t->clear_emails();
};

for my $user2 ( $schema->resultset('User')->find( { name => 'test2' } ) ) {
    ok !$user2->has_role('site_admin'), "2nd user created hasn't 'site_admin' role";
    ok $user2->has_role('private_projects'), "2nd user created has 'private_projects' role";
}

subtest "registration of existing username fails" => sub {
    $t->follow_link_ok( { text => 'Sign up' } );

    $t->submit_form_ok( { with_fields => { username => 'TEST2' }, }, "register account 'TEST2'" );

    $t->content_like(qr/username/)
      or note $t->content;
};

subtest "registration with invalid username fails" => sub {
    $t->follow_link_ok( { text => 'Sign up' } );

    $t->submit_form_ok( { with_fields => { username => $_ } }, "register account '$_'" ) for "foobar ";

    $t->content_like(qr/username/)
      or note $t->content;
};

$t->login_fails( 'test', 'invalid' );    # wrong password

$t->login_fails( 'test2', 's3cr3t' );    # not verified

{
    my $t1 = time();
    $t->login_ok( 'test', 's3cr3t' );
    my $t2 = time();

    cmp_ok $t2 - $t1, '>', 1, "login request took more than 1 second";
}

$t->change_password_ok(
    {
        old_password  => 's3cr3t',
        new_password  => 'P@ssw0rd',
        new_password2 => 'P@ssw0rd',
    },
);

$t->email_like(qr/ password .+ changed /x);

$t->clear_emails;

$t->change_display_name_ok('John Doe');

$t->logout_ok();

$t->get_ok('/login');

$t->content_like( qr/ name="username" .+ value="test" /x,
    "last username is prefilled in login form" );

is $t->cookie_jar->get_cookies( $t->base, 'username' ) => 'test',
  "'username' cookie contains username 'test'";

{
    my $original_length = length $t->cookie_jar->as_string;

    $t->cookie_jar->clear( 'localhost.local', '/', 'coocook_session' );

    $original_length > length $t->cookie_jar->as_string
      or die "failed to delete session cookie";
}

$t->reload();
$t->content_like( qr/ name="username" .+ value="test" /x,
    "... but last username is still prefilled in login form" )
  or diag $t->content;

$t->login_ok( 'test', 'P@ssw0rd' );

$t->logout_ok();

subtest "expired password reset token URL" => sub {
    $t->request_recovery_link_ok('test@example.com');

    $schema->resultset('User')->update( { token_expires => '2000-01-01 00:00:00' } );

    $t->get_email_link_ok(qr/http\S+reset_password\S+/);

    $t->content_like(qr/expired/);

    $t->clear_emails();
};

subtest "password recovery" => sub {
    $t->recover_account_ok( 'test@example.com', 'new, nice & shiny' );

    $t->logout_ok();

    $t->clear_emails();
};

subtest "password recovery marks e-mail address verified" => sub {
    my $test2 = $schema->resultset('User')->find( { name => 'test2' } );

    is $test2->email_verified => undef,
      "email_verified IS NULL";

    $t->recover_account_ok( 'test2@example.com', 'sUpEr s3cUr3' );

    $test2->discard_changes;
    isnt $test2->email_verified => undef,
      "email_verified IS NOT NULL";

    $t->logout_ok();
};

$t->login_ok( 'test', 'new, nice & shiny' );

subtest "redirects after login/logout" => sub {
    $t->get_ok('/about');

    $t->logout_ok();

    is $t->uri->path => '/about',
      "client is redirected to last page after logout"
      or diag "uri: " . $t->uri;

    # pass link around between login/register
    $t->follow_link_ok( { text => 'Sign up' } );

    $t->login_fails( 'test', 'invalid' );

    note "uri: " . $t->uri;

    $t->login_ok( 'test', 'new, nice & shiny' );

    is $t->uri->path => '/about',
      "client is redirected to last page after login"
      or diag "uri: " . $t->uri;
};

subtest "refreshing login page after logging in other browser tab" => sub {
    $t->get_ok('/login?redirect=statistics');

    is $t->uri->path => '/statistics',
      "client is redirected immediately"
      or diag "uri: " . $t->uri;
};

subtest "refreshing register page after logging in other browser tab" => sub {
    $t->get_ok('/register?redirect=statistics');

    is $t->uri->path => '/statistics',
      "client is redirected immediately"
      or diag "uri: " . $t->uri;
};

subtest "malicious redirects are filtered on logout" => sub {
    $t->is_logged_in();

    $t->post('/logout?redirect=https://malicious.example/');
    is $t->uri => 'https://localhost/', "client is redirected to /";

    $t->is_logged_out("... but client is logged out anyway");
};

subtest "malicious redirects are filtered on login" => sub {
    $t->post(
        '/login?redirect=https://malicious.example/',
        { username => 'test', password => 'new, nice & shiny' }
    );
    is $t->uri => 'https://localhost/', "client is redirected to /";
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
    is $t->uri => 'https://localhost/', "client is redirected to /";
    $t->is_logged_in("... but client is logged in anyway");
};

$t->create_project_ok( { name => "Test Project 1" } );

unlike $t->uri => qr/import/,
  "not redirected to importer for first project";

note "remove all roles from user";
$schema->resultset('RoleUser')->search( { user => '1' } )->delete;

$t->create_project_ok( { name => "Test Project 2" } );

like $t->uri => qr/import/,
  "redirected to importer";

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
