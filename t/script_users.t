use strict;
use warnings;

use DateTime::Format::SQLite;
use Test::Most;
use Test::Deep;

use_ok 'Coocook::Script::Users';

my $script = new_ok 'Coocook::Script::Users';

throws_ok { Coocook::Script::Users->new( discard => 1, email_verified => undef )->run() }
qr/discard/, "rejects discard=1 and email_verified=''";

throws_ok { Coocook::Script::Users->new( discard => 1, email_verified => 1 )->run() }
qr/discard/, "rejects discard=1 and email_verified=1";

my $now = DateTime::Format::SQLite->parse_datetime('2000-01-01 12:34:56');

sub parse { $script->_parse_created( shift, $now ) }

is parse(undef) => undef, "undef";

throws_ok { parse("foobar") } qr/invalid/i;

my @tests = (
    [ '+1d' => { created => { '<=', '1999-12-31 12:34:56' } } ],
    [ '-1w' => { created => { '>=', '1999-12-25 12:34:56' } } ],
    [ '+1m' => { created => { '<=', '1999-12-01 12:34:56' } } ],
    [ '-1y' => { created => { '>=', '1999-01-01 12:34:56' } } ],
);

for (@tests) {
    my ( $input => $expected ) = @$_;

    cmp_deeply parse($input) => $expected, $input;
}

done_testing;
