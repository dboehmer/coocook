use strict;
use warnings;

use lib 't/lib';

use DBICx::TestDatabase;
use Test::Coocook;
use Test::Most tests => 17;

our $SCHEMA = DBICx::TestDatabase->new('Coocook::Schema');

my $t = Test::Coocook->new();

$t->get_ok('/');

$t->register_ok(
    {
        name         => "test",
        display_name => "Test User",
        email        => "test\@example.com",
        password     => "s3cr3t",
        password2    => "s3cr3t",
    }
);

$t->verify_email_ok();

$t->register_ok(
    {
        name         => "test2",
        display_name => "Other User",
        email        => "test2\@example.com",
        password     => "s3cr3t",
        password2    => "s3cr3t",
    }
);

$t->login_fails( 'test', 'invalid' );    # wrong password

$t->login_fails( 'test2', 's3cr3t' );    # not verified

$t->login_ok( 'test', 's3cr3t' );

$t->change_password_ok(
    {
        old_password  => 's3cr3t',
        new_password  => 'P@ssw0rd',
        new_password2 => 'P@ssw0rd',
    },
);

$t->change_display_name_ok('John Doe');

$t->logout_ok();

$t->login_ok( 'test', 'P@ssw0rd' );

subtest "create project" => sub {
    $t->submit_form_ok(
        {
            with_fields  => { name => "Test Project" },
            strict_forms => 1,
        },
        "submit create project form"
    );

    $t->get_ok('/');
    $t->content_like(qr/Test Project/)
      or note $t->content;
};

my $users = $SCHEMA->resultset('User');

is $users->find( { name => 'test' } )->role => 'admin',
  "1st user created has 'admin' role";

is $users->find( { name => 'test2' } )->role => 'user',
  "2nd user created has 'user' role";

ok my $project = $SCHEMA->resultset('Project')->find( { name => "Test Project" } ),
  "project is in database";

is $project->owner->name => 'test',
  "new project is owned by new user";

is $project->users->first->name => 'test',
  "owner relationship is also stored via table 'projects_users'";
