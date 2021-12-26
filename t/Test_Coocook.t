use Test2::V0;

use lib 't/lib';
use Test::Coocook;

like dies { Test::Coocook->new( deploy => 0, schema => "schema_object" ) } => qr/arguments/,
  "fails with conflicting arguments 'deploy' and 'schema'";

ok my $t = Test::Coocook->new();

subtest reload_config => sub {
    my $app = $t->catalyst_app;

    ok !$app->config->{TEST};
    ok $t->reload_config( { TEST => 1 } );
    ok $app->config->{TEST};

    ok !$app->config->{TEST2};
    ok my $guard = $t->local_config_guard( { TEST2 => 1 } );
    ok $app->config->{TEST2};
    undef $guard;

    todo "reload_config() doesn't remove unused keys, only sets original values" => sub {
        ok !$app->config->{TEST2};
    };
};

is intercept( sub { $t->reload_ok } )->squash_info->flatten => array {
    item hash {
        field pass       => 0;
        field trace_file => __FILE__;
        field trace_line => __LINE__ - 4;
        etc();
    };
};

$ENV{DBIC_KEEP_TEST}
  or is(    # turn undef into '' because of https://github.com/DBD-SQLite/DBD-SQLite/issues/50
    $t->schema->storage->dbh->sqlite_db_filename // '' => '',
    "is a temporary SQLite database"
  );

done_testing;
