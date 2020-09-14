use strict;
use warnings;

use Test2::Require::Module 'Test::PostgreSQL';

use Coocook::Script::Deploy;
use Coocook::Schema;
use DBIx::Diff::Schema qw(diff_db_schema);
use Test::Deep;
use Test::Most;

my $FIRST_PGSQL_SCHEMA_VERSION = 21;

my $pg_dbic = Test::PostgreSQL->new();
ok my $schema_dbic = Coocook::Schema->connect( $pg_dbic->dsn );
lives_ok { $schema_dbic->deploy() } "deploy with DBIC";

my $pg_deploy = Test::PostgreSQL->new();
ok my $schema_deploy = Coocook::Schema->connect( $pg_deploy->dsn );
my $app_deploy = Coocook::Script::Deploy->new( _schema => $schema_deploy );
ok $app_deploy->_dh->install(), "deploy with DeploymentHandler->install()";

# TODO doesn't detect constraint changes, e.g. missing UNIQUEs
my $diff = diff_db_schema( map { $_->storage->dbh } $schema_dbic, $schema_deploy );
is_deeply $diff => {
    'added_tables' => [
        'public.dbix_class_deploymenthandler_versions',    # not created by DBIC
    ],
  },
  "database schemas equal"
  or diag explain $diff;

# TODO test upgrades

done_testing;
