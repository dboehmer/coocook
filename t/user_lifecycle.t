use strict;
use warnings;

use lib 't/lib';

use TestDB;
use Test::Most;
use Test::WWW::Mechanize::Catalyst;

our $SCHEMA = TestDB->new;

ok my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'Coocook' );

$t->get_ok('/');

$t->follow_link_ok( { text => 'Register' } );

$t->submit_form_ok(
    {
        with_fields => {
            name         => "test",
            display_name => "Test User",
            email        => "test\@example.com",
            password     => "s3cr3t",
            password2    => "s3cr3t",
        },
        strict_forms => 1,
    }
);

$t->click_ok('logout');

$t->follow_link_ok( { text => 'Login' } );

$t->submit_form_ok(
    {
        with_fields => {
            username => 'test',
            password => 's3cr3t',
        },
        strict_forms => 1,
    }
);

$t->submit_form_ok(
    {
        with_fields  => { name => "Test Project" },
        strict_forms => 1,
    }
);

$t->get_ok('/');
$t->content_like(qr/Test Project/);

is $SCHEMA->resultset('Project')->find( { name => "Test Project" } )->owner->name => 'test',
  "new project is owned by new user";

done_testing;
