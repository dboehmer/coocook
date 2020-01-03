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

    email_not_ok 'somebody@example.com';
    email_ok 'anybody-else@example.com';

    email_not_ok 'any@coocook.example';
    email_ok 'any@safe-subdomain.coocook.example';

    email_not_ok 'any@coocook.org';
    email_not_ok 'any@any-subdomain.coocook.org';

    email_not_ok 'SOMEBODY@EXAMPLE.COM', "uppercase literal e-mail";
    email_not_ok 'ANY@COOCOOK.ORG',      "uppercase wildcard pattern";

    subtest add_email => sub {
        can_ok $blacklist, 'add_email';

        my $literal = 'literal@example.com';

        ok $blacklist->is_email_ok($literal);
        ok $blacklist->add_email( $literal, comment => __FILE__ );
        ok !$blacklist->is_email_ok($literal);
        ok !$blacklist->is_email_ok( uc $literal ), "uppercase";
        ok !$blacklist->exists( { email_fc => $literal } ),
          "table doesn't contain e-mail address in cleartext";
    };
};

subtest BlacklistUsername => sub {
    ok $blacklist = $db->resultset('BlacklistUsername'), "table exists";

    can_ok $blacklist, 'is_username_ok';
};
