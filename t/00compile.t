use strict;
use warnings;

use Test::Compile;

# would love to use all_files_ok() including *.pl files but
# https://rt.cpan.org/Ticket/Display.html?id=118530
#my $t = Test::Compile->new();
#$t->all_files_ok;
#$t->done_testing;

all_pm_files_ok();
