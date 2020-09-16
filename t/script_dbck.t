use strict;
use warnings;

use lib 't/lib/';

use Coocook;
use TestDB;
use Test::Output;
use Test::Most tests => 2;

use_ok 'Coocook::Script::Dbck';

my $db = TestDB->new();
Coocook->model('DB')->schema->storage( $db->storage );

warning_is { my $app = Coocook::Script::Dbck->new_with_options()->run() } undef;
