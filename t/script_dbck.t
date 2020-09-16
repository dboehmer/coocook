use strict;
use warnings;

use lib 't/lib/';

use Coocook;
use TestDB;
use Test::Output;
use Test::Most tests => 3;

use_ok 'Coocook::Script::Dbck';

my $db = TestDB->new();

ok my $app = Coocook::Script::Dbck->new_with_options();

$app->_schema($db);

warning_is { $app->run } undef;
