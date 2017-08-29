use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Most;

use_ok 'Coocook::Schema';

ok my $db = TestDB->new;

is $db->count()                   => 51, "count()";
is $db->count(qw< Article Unit >) => 10, "count(Article Unit)";

done_testing;
