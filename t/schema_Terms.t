use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Most;    #tests => 7;

my $db = TestDB->new;

ok my $rs = $db->resultset('Terms'), "new resultset";

is $rs->valid_on_date('2001-01-01') => undef, "valid_on_date() on empty database";
is $rs->valid_today()               => undef, "valid_today() on empty database";

ok $rs->populate(
    [
        [ 'valid_from', 'content_md' ],
        [ '2001-01-01', "A" ],
        [ '2002-01-01', "B" ],
        [ '2003-01-01', "C" ],
        [ '2004-01-01', "D" ],
        [ '2005-01-01', "E" ],
    ]
  ),
  "populate";

throws_ok { $rs->create( { valid_from => '2001-01-01', content_md => "" } ) } qr/UNIQUE/,
  "INSERT with non-unique date fails";

subtest "valid_on_date() with string" => sub {
    is $rs->valid_on_date('2000-01-01')             => undef, "undef for previous dates";
    is $rs->valid_on_date('2001-01-01')->content_md => "A",   "first date";
    is $rs->valid_on_date('2001-12-31')->content_md => "A",   "right before second date";
    is $rs->valid_on_date('2002-01-01')->content_md => "B",   "second date";
    is $rs->valid_on_date('2100-01-01')->content_md => "E",   "far in the future";

    local $TODO = "check not implemented yet";
    throws_ok { $rs->valid_on_date('foobar') } qr/format/, "throws exception for invalid date format";
};

is $rs->valid_today->content_md => "E", "valid_today()";

my $c = $rs->find( { content_md => "C" } ) || die;

is $c->next()->content_md  => "D",   "next()";
is $c->next(2)->content_md => "E",   "next(2)";
is $c->next(99)            => undef, "next(99)";

is $c->previous()->content_md => "B", "previous()";
is $c->previous($_)->content_md => "A",   "previous($_)" for -2,  2;
is $c->previous($_)             => undef, "previous($_)" for -99, 99;

done_testing;
