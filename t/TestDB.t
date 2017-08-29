use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use Test::Most;

use_ok 'TestDB';

ok my $db = TestDB->new, "TestDB->new";

ok $db->count, "deployed";

ok my $db2 = TestDB->new, "another instance";

ok $db2->count, "... is also populated";

ok $db->resultset('Unit')->delete, "delete table in 1st instance";

ok $db2->resultset('Unit')->count, "table still populated in 2nd instance";

done_testing;
