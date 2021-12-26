use Test2::V0;
use Test::Compile v2.2.2;

$ENV{$_} and plan skip_all => "$_ is set" for 'COOCOOK_SKIP_COMPILE';

my $t = Test::Compile->new();
$t->all_files_ok;
$t->done_testing;
