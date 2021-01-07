use strict;
use warnings;

use lib 't/lib';

use DateTime;
use Test::Coocook;
use Test::Most tests => 56;

my $t = Test::Coocook->new;

my $john_doe = $t->schema->resultset('User')->find( { name => 'john_doe' } );
my $other    = $t->schema->resultset('User')->find( { name => 'other' } );

my $johns_old_email       = $john_doe->email_fc;
my $johns_cancelled_email = 'john2.0@example.com';
my $johns_new_email       = 'john3.0@example.com';

my $year = DateTime->today->year;

$t->get_ok('/');
$t->login_ok( 'john_doe', 'P@ssw0rd' );

$t->follow_link_ok( { text => 'settings Settings' } );
$t->submit_form_fails( { with_fields => { new_email => 'invalid' } },
    "post invalid email address" );
my $content_invalid_email = $t->content;
$t->back();

$t->submit_form_fails( { with_fields => { new_email => $other->email_fc } },
    "post existing address" );
$t->content_is( $content_invalid_email, "no information leak" );
$t->back();

$t->submit_form_fails( { with_fields => { new_email => 'imposter@coocook.org' } },
    "blacklisted address" );
$t->content_is( $content_invalid_email, "no information leak" );
$t->back();

$other->update(
    {
        new_email_fc  => $johns_new_email,
        token_hash    => 'random',
        token_created => $other->format_datetime( DateTime->now ),
        token_expires => $other->format_datetime( DateTime->now->add( hours => 12 ) ),
    }
);

$t->submit_form_fails( { with_fields => { new_email => $other->new_email_fc } },
    "post new_email_fc of other account" );
$t->content_is( $content_invalid_email, "no information leak" );
$t->back();

subtest "registration works if other user tried to change to same address but request expired" =>
  sub {
    $t->clear_emails();

    note "email change of other user expires ...";
    $other->update( { token_expires => $other->format_datetime_now } );

    $t->schema->txn_begin();

    $t->submit_form_ok( { with_fields => { new_email => $johns_new_email } } );
    $t->email_count_is(2);
    $t->back();

    $t->submit_form_ok( { with_fields => { new_email => $johns_new_email } },
        "form can be sent again" );
    $t->email_count_is(4);
    $t->back();

    $t->schema->txn_rollback();    # undo changes

    $t->clear_emails();
  };

$t->submit_form_ok( { with_fields => { new_email => $johns_old_email } }, "same email address" );
$t->text_lacks('verification link');

$t->submit_form_ok( { with_fields => { new_email => $johns_cancelled_email } } );
$t->text_contains('verification link');
cols_are_set();

# email to current_address
$t->email_like( qr/John Doe/, "user's display name" );
$t->email_like( qr/john_doe/, "username" );

$t->get_ok_email_link_like( qr{/settings/account}, "follow link to change password" );
$t->text_like(qr/change (your )?password/i);

$t->cookie_jar->clear()
  and note "cleared cookies";

$t->get_ok_email_link_like( qr{/settings}, "follow link to account settings" );
$t->submit_form_ok( { with_fields => { username => 'john_doe', password => 'P@ssw0rd' } },
    "login again" );
$t->text_contains($johns_cancelled_email);
$t->text_contains( $year, "text contains timestamp of request" );

$t->submit_form_ok( { form_name => "cancel_email_change" } );
$t->text_contains("cancelled");
$t->text_contains($johns_cancelled_email);

$t->shift_emails();
$t->get_ok_email_link_like( qr{verify}, 400, "verification link is now 400" );

$t->shift_emails();
$t->email_count_is( 0, "no more emails" );

$t->reload_ok();
$t->text_lacks($johns_cancelled_email);

cols_are_null();
is $john_doe->email_fc => $johns_old_email, "email address wasn't changed";

$t->follow_link_ok( { text        => 'settings Settings' } );
$t->submit_form_ok( { with_fields => { new_email => $johns_new_email } } );

$t->cookie_jar->clear()
  and note "cleared cookies";

# first email already checked above
$t->shift_emails();

# email to new address
$t->email_like( qr/John Doe/, "user's display name" );
$t->email_like( qr/john_doe/, "username" );
$t->get_ok_email_link_like( qr{verify}, "follw link to verify address change" );

$t->shift_emails();
$t->email_count_is( 0, "no more emails left" );

$t->submit_form_ok( { with_fields => { username => 'john_doe', password => 'P@ssw0rd' } },
    "login again" );

cols_are_set();
is $john_doe->email_fc => $johns_old_email, "email address didn't change yet";

$t->submit_form_ok( { form_name => 'confirm_email_change' } );

cols_are_null();
is $john_doe->email_fc => $johns_new_email, "email address has changed";

subtest "password recovery after email change request" => sub {
    $t->submit_form_ok( { with_fields => { new_email => $johns_cancelled_email } } );
    cols_are_set();
    $t->clear_emails();
    $t->request_recovery_link_ok($johns_new_email);
    cols_are_null('new_email_fc');
    $t->submit_form_ok( { with_fields => { password => 'p', password2 => 'p' } }, "reset password" );
    cols_are_null();
};

sub cols_are_null {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $john_doe->discard_changes();
    is( $john_doe->get_column($_) => undef, "$_ is NULL" )
      for @_ ? @_ : (qw< new_email_fc token_hash token_created token_expires >);
}

sub cols_are_set {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $john_doe->discard_changes();
    ok $john_doe->get_column($_), "$_ is set" for qw< token_hash token_created token_expires >;
}
