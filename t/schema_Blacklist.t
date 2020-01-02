use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Most tests => 2;

my $db = TestDB->new();

my $blacklist;    # allow access from sub

subtest BlacklistEmail => sub {
    ok $blacklist = $db->resultset('BlacklistEmail'), "table exists";

    ok $blacklist->populate(
        [
            { email => 'foo@example.com' },
            { email => 'bar@example.com' },

            { email => '*@foo.example', wildcard => 1 },

            { email => '*@bar.example',   wildcard => 1 },
            { email => '*@*.bar.example', wildcard => 1, comment => "subdomains also" },
        ]
      ),
      "populate";

    can_ok $blacklist, 'is_email_ok';

    sub email_ok {
        my ( $email, $name ) = @_;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        ok $blacklist->is_email_ok($email), $name || "$email is ok";
    }

    sub email_not_ok {
        my ( $email, $name ) = @_;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        ok !$blacklist->is_email_ok($email), $name || "$email is not ok";
    }

    email_not_ok 'foo@example.com';
    email_not_ok 'bar@example.com';
    email_ok 'baz@example.com';

    email_not_ok 'any@foo.example';
    email_ok 'any@safe-subdomain.foo.example';

    email_not_ok 'any@foobar.example';
    email_not_ok 'any@any-subdomain.foobar.example';
};

subtest BlacklistUsername => sub {
    ok $blacklist = $db->resultset('BlacklistUsername'), "table exists";

    can_ok $blacklist, 'is_username_ok';
};
