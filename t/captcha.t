use strict;
use warnings;

use lib 't/lib';

use DBICx::TestDatabase;
use Test::Coocook;
use Test::Most tests => 6;

my $t = Test::Coocook->new( deploy => 0 );

my %ok_input = (
    username  => 'test',
    email     => 'test@example.com',
    password  => 's3cr3t',
    password2 => 's3cr3t',
);

subtest "POST /register without session" => sub {
    $t->post( 'https://localhost/register', \%ok_input );

    $t->status_is(400);
    $t->content_like(qr/robot/);
};

$t->reload_config( captcha => { use_hidden_input => 1 } );
$t->register_fails_like( { %ok_input, url => 'https://www.spam.example/' },
    qr/robot/, "use_hidden_input" );

$t->reload_config( captcha => { form_min_time_secs => 42 } );
$t->register_fails_like( \%ok_input, qr/robot/, "form_min_time_secs" );

subtest "form_max_time_secs" => sub {
    $t->reload_config( captcha => { form_max_time_secs => 1 } );

    $t->get_ok('/register');
    sleep 2;
    $t->submit_form( with_fields => \%ok_input );

    $t->status_is(400);
    $t->content_like(qr/robot/);
};

$t->reload_config( captcha => { form_min_time_secs => undef } );
ok !$t->schema->resultset('User')->find( { name => $_ } ), "no user '$_' has been created"
  for $ok_input{username};

$t->register_ok( \%ok_input, "countercheck: register works" );
