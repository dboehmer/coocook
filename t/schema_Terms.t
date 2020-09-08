use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Most tests => 15;

my $db = TestDB->new;

ok my $rs = $db->resultset('Terms'), "new resultset";

$rs->delete();    # delete test data

is $rs->valid_on_date('2001-01-01') => undef, "valid_on_date() on empty database";
is $rs->valid_today()               => undef, "valid_today() on empty database";

ok !$rs->valid_today_rs->results_exist, "valid_today_rs()->results_exist returns false";

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

ok $rs->valid_today_rs->results_exist, "valid_today_rs()->results_exist returns true";

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

my ( $a, $b, $c, $d, $e ) = map { $rs->find( { content_md => $_ } ) || die } 'A' .. 'E';

subtest neighbors => sub {
    is $a->neighbors(-1)->count => 0, "no A->neighbors(-1)";
    is $a->neighbors(+1)->count => 4, "A->neighbors(+1)";

    is $d->neighbors(-1)->count => 3, "D->neighbors(-1)";
    is $d->neighbors(+1)->count => 1, "D->neighbors(+1)";

    throws_ok { $c->neighbors( () ) } qr/defined/, "argument missing";
    throws_ok { $c->neighbors(undef) } qr/defined/, "undef";
    throws_ok { $c->neighbors(0) } qr/zero/,        "0";
};

subtest next => sub {
    is $c->next()->content_md  => "D",   "C->next()";
    is $c->next(2)->content_md => "E",   "C->next(2)";
    is $c->next(99)            => undef, "C->next(99)";
};

subtest previous => sub {
    is $c->previous()->content_md   => "B",   "C->previous()";
    is $c->previous($_)->content_md => "A",   "C->previous($_)" for -2,  2;
    is $c->previous($_)             => undef, "C->previous($_)" for -99, 99;
};

subtest cmp_validity_today => sub {
    for (qw< CMP_VALID_IN_PAST CMP_VALID_TODAY CMP_VALID_IN_FUTURE >) {
        ok defined ${ $Coocook::Schema::Result::Terms::{$_} }, "\$Result::Terms::$_ is defined";
    }

    # TODO calling cmp_validity_today() seems to have side effects!
    # without calling discard_changes() the next check on $e reports $CMP_VALID_TODAY
    is $e->cmp_validity_today => $Coocook::Schema::Result::Terms::CMP_VALID_TODAY, "E is valid";
    $e->discard_changes;    # TODO why is this necessary?!

    note "Update C to today and D,E to far future ...";
    $c->update( { valid_from => DateTime->today->ymd } );
    $d->update( { valid_from => '2099-01-01' } );
    $e->update( { valid_from => '2100-01-01' } );

    no warnings 'once';

    is $a->cmp_validity_today => $Coocook::Schema::Result::Terms::CMP_VALID_IN_PAST, "A was valid";
    is $c->cmp_validity_today => $Coocook::Schema::Result::Terms::CMP_VALID_TODAY,   "C is valid";
    is $e->cmp_validity_today => $Coocook::Schema::Result::Terms::CMP_VALID_IN_FUTURE,
      "E will be valid";
};

subtest reasons_to_freeze => sub {
    is $a->reasons_to_freeze => 'not_in_future', "A is not in future (past)";
    is $c->reasons_to_freeze => 'not_in_future', "C is not in future (valid today)";
    is $d->reasons_to_freeze => undef,           "D can be edited";
    is $e->reasons_to_freeze => undef,           "E can be edited";
};

subtest reasons_to_keep => sub {
    is $a->reasons_to_keep => undef,                "A can be deleted";
    is $b->reasons_to_keep => 'has_previous',       "B has previous neighbor";
    is $c->reasons_to_keep => 'is_currently_valid', "C is currently valid";
    is $d->reasons_to_keep => 'has_next',           "D has next neighbor";
    is $e->reasons_to_keep => undef,                "E can be deleted";
};
