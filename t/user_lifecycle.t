use strict;
use warnings;

use lib 't/lib';

# don't actually send any e-mails
BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }

use Email::Sender::Simple;
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

my @deliveries = Email::Sender::Simple->default_transport->deliveries;

is scalar @deliveries => 1, "sent 1 e-mail";

my $email = $deliveries[0]->{email};
note $email->as_string;

my @urls =
  ( $email->get_body =~ m/http\S+verify\S+/g );    # TODO regex is very simple and will break easily

is scalar @urls => 1, "found 1 URL";

my $verification_url = $urls[0];

$t->get_ok($verification_url);

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

$t->follow_link_ok( { text => 'Settings' } );

$t->submit_form_ok(
    {
        with_fields => {
            old_password  => 's3cr3t',
            new_password  => 'P@ssw0rd',
            new_password2 => 'P@ssw0rd',
        },
        strict_forms => 1,
    }
);

$t->submit_form_ok(
    {
        with_fields => {
            display_name => 'John Doe',
        },
        strict_forms => 1,
    }
);
$t->get_ok('/');
$t->content_like(qr/John Doe/);

$t->click_ok('logout');

$t->follow_link_ok( { text => 'Login' } );
$t->submit_form_ok(
    {
        with_fields => {
            username => 'test',
            password => 'P@ssw0rd',
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
