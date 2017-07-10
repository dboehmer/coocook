use strict;
use warnings;

use Test::Most;

use_ok 'TestDB';

ok my $db = TestDB->new, "TestDB->new";

ok $db->resultset('Unit')->count;

done_testing;
