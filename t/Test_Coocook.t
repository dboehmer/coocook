use strict;
use warnings;

use lib 't/lib';

use Test::Most;

use_ok 'Test::Coocook';

throws_ok { Test::Coocook->new( deploy => 0, schema => "schema_object" ) } qr/arguments/,
  "fails with conflicting arguments 'deploy' and 'schema'";

my $t = new_ok 'Test::Coocook';

can_ok $t => 'reload_config';

$ENV{DBIC_KEEP_TEST}
  or is(    # turn undef into '' because of https://github.com/DBD-SQLite/DBD-SQLite/issues/50
    $t->schema->storage->dbh->sqlite_db_filename // '' => '',
    "is a temporary SQLite database"
  );

done_testing;
