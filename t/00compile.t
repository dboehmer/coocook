use strict;
use warnings;

use Test::Compile v2.2.2;

my $t = Test::Compile->new();
$t->all_files_ok;
$t->done_testing;
