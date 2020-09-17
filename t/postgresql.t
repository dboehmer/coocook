use strict;
use warnings;

use Test2::Require::Module 'Test::PostgreSQL';

use Coocook::Script::Deploy;
use Coocook::Schema;
use DBIx::Diff::Schema qw(diff_db_schema);
use Test::Deep;
use Test::Most;

my $FIRST_PGSQL_SCHEMA_VERSION = 21;

my $dbic_pg = Test::PostgreSQL->new();
ok my $dbic_schema = Coocook::Schema->connect( $dbic_pg->dsn );
lives_ok { $dbic_schema->deploy() } "deploy with DBIx::Class";

my $dh_pg = Test::PostgreSQL->new();
ok my $dh_schema = Coocook::Schema->connect( $dh_pg->dsn );
my $dh_app = Coocook::Script::Deploy->new( _schema => $dh_schema );
ok $dh_app->_dh->install(), "deploy with DeploymentHandler->install()";

# TODO doesn't detect constraint changes, e.g. missing UNIQUEs
my $diff = diff_db_schema( map { $_->storage->dbh } $dbic_schema, $dh_schema );
is_deeply $diff => {
    'added_tables' => [
        'public.dbix_class_deploymenthandler_versions',    # not created by DBIC
    ],
  },
  "database schemas equal"
  or diag explain $diff;

# TODO test upgrades

done_testing;
