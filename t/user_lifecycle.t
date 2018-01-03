use strict;
use warnings;

use lib 't/lib';

# don't actually send any e-mails
BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }

use Email::Sender::Simple;
use DBICx::TestDatabase;
use Test::Most;
use Test::WWW::Mechanize::Catalyst;

our $SCHEMA = DBICx::TestDatabase->new('Coocook::Schema');

ok my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'Coocook' );

sub register_ok {
    my ($field_values) = @_;

    $t->get_ok('/');

    $t->follow_link_ok( { text => 'Register' } );

    $t->submit_form_ok(
        {
            with_fields  => $field_values,
            strict_forms => 1,
        },
        "register account"
    );

    subtest "try login after registration before verification" => sub {
        $t->follow_link_ok( { text => 'Login' } );

        $t->submit_form_ok(
            {
                with_fields => {
                    username => $field_values->{name},
                    password => $field_values->{password},    # right password but account not yet verified!
                },
                strict_forms => 1,
            },
            "submit login form"
        );

        ( $t->content_like(qr/fail/) and $t->content_like(qr/Login/) )
          or note $t->content;
    };

    my @deliveries = Email::Sender::Simple->default_transport->deliveries;

    ok my $email = pop(@deliveries)->{email}, "sent 1 e-mail";
    note $email->as_string;

    my @urls =
      ( $email->get_body =~ m/http\S+verify\S+/g );    # TODO regex is very simple and will break easily

    is scalar @urls => 1, "found 1 URL";

    my $verification_url = $urls[0];

    $t->get_ok($verification_url);

    subtest "failing login with wrong password" => sub {
        $t->follow_link_ok( { text => 'Login' } )
          or note $t->content;

        $t->submit_form_ok(
            {
                with_fields => {
                    username => 'test',
                    password => 'invalid',    # wrong password
                },
                strict_forms => 1,
            },
            "submit login form"
        );

        $t->content_like(qr/fail/);
        $t->content_like(qr/Login/);
    };
}

register_ok {
    name         => "test",
    display_name => "Test User",
    email        => "test\@example.com",
    password     => "s3cr3t",
    password2    => "s3cr3t",
};

register_ok {
    name         => "test2",
    display_name => "Other User",
    email        => "test2\@example.com",
    password     => "s3cr3t",
    password2    => "s3cr3t",
};

$t->follow_link_ok( { text => 'Login' } );

$t->submit_form_ok(
    {
        with_fields => {
            username => 'test',
            password => 's3cr3t',
        },
        strict_forms => 1,
    },
    "submit login form"
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
    },
    "submit change password form"
);

$t->submit_form_ok(
    {
        with_fields => {
            display_name => 'John Doe',
        },
        strict_forms => 1,
    },
    "submit change display name form"
);
$t->get_ok('/');
$t->content_like(qr/John Doe/);

$t->click_ok( 'logout', "click logout button" );

$t->follow_link_ok( { text => 'Login' } );
$t->submit_form_ok(
    {
        with_fields => {
            username => 'test',
            password => 'P@ssw0rd',
        },
        strict_forms => 1,
    },
    "submit login form"
);

$t->submit_form_ok(
    {
        with_fields  => { name => "Test Project" },
        strict_forms => 1,
    },
    "submit rename project form"
);

$t->get_ok('/');
$t->content_like(qr/Test Project/)
  or note $t->content;

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

done_testing;
