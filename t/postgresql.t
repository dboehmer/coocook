use strict;
use warnings;

use Test2::Require::Module 'Test::PostgreSQL';

use Coocook::Script::Deploy;
use Coocook::Schema;
use DBIx::Diff::Schema qw(diff_db_schema);
use Test::Deep;
use Test::Most;

use lib 't/lib';
use TestDB qw(install_ok upgrade_ok);

my $FIRST_PGSQL_SCHEMA_VERSION = 21;

plan tests => 5 + 4 * ( $Coocook::Schema::VERSION - $FIRST_PGSQL_SCHEMA_VERSION ) + 1;

my $pg_dbic = Test::PostgreSQL->new();
ok my $schema_from_dbic = Coocook::Schema->connect( $pg_dbic->dsn );
lives_ok { $schema_from_dbic->deploy() } "deploy with DBIx::Class";

my $pg_deploy = Test::PostgreSQL->new();
ok my $schema_from_deploy = Coocook::Schema->connect( $pg_deploy->dsn );

my $pg_upgrades = Test::PostgreSQL->new();
ok my $schema_from_upgrades = Coocook::Schema->connect( $pg_upgrades->dsn );
install_ok( $schema_from_upgrades, $FIRST_PGSQL_SCHEMA_VERSION );

for my $version ( $FIRST_PGSQL_SCHEMA_VERSION + 1 .. $Coocook::Schema::VERSION ) {
    $pg_deploy = Test::PostgreSQL->new();
    ok $schema_from_deploy = Coocook::Schema->connect( $pg_deploy->dsn );
    install_ok( $schema_from_deploy, $version );

    upgrade_ok( $schema_from_upgrades, $version );

    schema_diff_like( $schema_from_upgrades, $schema_from_deploy, {},
        "schema version $version from upgrade SQLs and schema from deploy SQL are equal" );
}

my $sqlite_schema = TestDB->new();

# rename Pgsql schema to match SQLite schema name 'main'
$schema_from_deploy->storage->dbh_do( sub { $_[1]->do('ALTER SCHEMA public RENAME TO main') } );

schema_diff_like(
    $schema_from_deploy,
    $sqlite_schema,
    {
        deleted_tables => [
            'main.dbix_class_deploymenthandler_versions',    # not created by DBIC
        ],
        modified_tables => {
            map ( {
                    (    # SQLite PKs are deployed with uppercase 'id INTEGER PRIMARY KEY'
                        'main.' . $_ => { modified_columns => { id => { old_type => 'integer', new_type => 'INTEGER' } } }
                    )
                } qw<
                  articles
                  blacklist_emails
                  blacklist_usernames
                  dishes
                  dish_ingredients
                  faqs
                  items
                  meals
                  organizations
                  projects
                  purchase_lists
                  quantities
                  recipe_ingredients
                  recipes
                  shop_sections
                  tag_groups
                  tags
                  terms
                  units
                  users
                  > ),
            map { 'main.' . $_ => ignore }    # https://github.com/perlancar/perl-DBIx-Diff-Schema/issues/1
              qw<
              dish_ingredients
              faqs
              items
              recipe_ingredients
              >
        },
    }
);

sub schema_diff_like {
    my ( $schema1, $schema2, $expected_diff, $name ) = @_;

    # TODO doesn't detect constraint changes, e.g. missing UNIQUEs
    my $diff = diff_db_schema( map { $_->storage->dbh } $schema1, $schema2 );

    cmp_deeply $diff => $expected_diff,
      $name // "database schemas equal"
      or diag explain $diff;
}
