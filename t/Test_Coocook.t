use strict;
use warnings;

use lib 't/lib';

use Test::Most;

use_ok 'Test::Coocook';

throws_ok { Test::Coocook->new( deploy => 0, schema => "schema_object" ) } qr/arguments/,
  "fails with conflicting arguments 'deploy' and 'schema'";

my $t = new_ok 'Test::Coocook';

subtest reload_config => sub {
    my $app = $t->catalyst_app;

    ok !$app->config->{TEST};
    ok $t->reload_config( { TEST => 1 } );
    ok $app->config->{TEST};

    ok !$app->config->{TEST2};
    ok my $guard = $t->local_config_guard( { TEST2 => 1 } );
    ok $app->config->{TEST2};
    undef $guard;

    local $TODO = "reload_config() doesn't remove unused keys, only sets original values";
    ok !$app->config->{TEST2};
};

$ENV{DBIC_KEEP_TEST}
  or is(    # turn undef into '' because of https://github.com/DBD-SQLite/DBD-SQLite/issues/50
    $t->schema->storage->dbh->sqlite_db_filename // '' => '',
    "is a temporary SQLite database"
  );

done_testing;
