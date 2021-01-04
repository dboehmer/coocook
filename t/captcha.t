use strict;
use warnings;

use lib 't/lib';

use Test::Coocook;
use Test::Most tests => 6;

my $t = Test::Coocook->new( test_data => 0 );

my %ok_input = (
    username  => 'test',
    email     => 'test@example.com',
    password  => 's3cr3t',
    password2 => 's3cr3t',
);

subtest "POST /register without session" => sub {
    $t->post( 'https://localhost/register', \%ok_input );

    $t->status_is(400);
    $t->text_like(qr/robot/);
};

{
    my $guard = $t->local_config_guard( captcha => { use_hidden_input => 1 } );
    $t->register_fails_like( { %ok_input, url => 'https://www.spam.example/' },
        qr/robot/, "use_hidden_input" );
}

{
    my $guard = $t->local_config_guard( captcha => { form_min_time_secs => 42 } );
    $t->register_fails_like( \%ok_input, qr/robot/, "form_min_time_secs" );
}

# TODO below are multiple sleep() calls. instead generate multiple $t and run tests quasi-parallel.
# (no threading, just split subtests in two and run all parts A, sleep once, then all parts B)

subtest "form_max_time_secs" => sub {
    my $guard = $t->local_config_guard( captcha => { form_max_time_secs => 1 } );

    $t->get_ok('/register');
    sleep 2;
    $t->submit_form_fails( { with_fields => \%ok_input } );
    $t->text_like(qr/robot/);
};

ok !$t->schema->resultset('User')->find( { name => $_ } ), "no user '$_' has been created"
  for $ok_input{username};

# a human users might enter invalid data, reload the format
# and fix their input quickly. this is still legit.
# time spent on the form shall add up over reloads.
subtest "form reloads add up to form_min_time_secs" => sub {
    my $guard = $t->local_config_guard( captcha => { form_min_time_secs => 3 } );
    $t->register_fails_like( \%ok_input, qr/robot/, "too fast" );
    sleep 2;
    $t->submit_form_fails( { with_fields => \%ok_input }, "still too fast" );
    sleep 2;

    # also countercheck: register works after all
    $t->submit_form_ok( { with_fields => \%ok_input }, "total time >= form_min_time_secs" );
};
