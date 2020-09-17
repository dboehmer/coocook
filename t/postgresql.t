use strict;
use warnings;

use Test2::Require::Module 'Test::PostgreSQL';

use Coocook::Script::Deploy;
use Coocook::Schema;
use DBIx::Diff::Schema qw(diff_db_schema);
use Test::Deep;
use Test::Most;

use lib 't/lib';
use TestDB;

my $FIRST_PGSQL_SCHEMA_VERSION = 21;

my $dbic_pg = Test::PostgreSQL->new();
ok my $dbic_schema = Coocook::Schema->connect( $dbic_pg->dsn );
lives_ok { $dbic_schema->deploy() } "deploy with DBIx::Class";

my $dh_pg = Test::PostgreSQL->new();
ok my $dh_schema = Coocook::Schema->connect( $dh_pg->dsn );
my $dh_app = Coocook::Script::Deploy->new( _schema => $dh_schema );
ok $dh_app->_dh->install(), "deploy with DeploymentHandler->install()";

{    # TODO doesn't detect constraint changes, e.g. missing UNIQUEs
    my $diff = diff_db_schema( map { $_->storage->dbh } $dbic_schema, $dh_schema );
    is_deeply $diff => {
        added_tables => [
            'public.dbix_class_deploymenthandler_versions',    # not created by DBIC
        ],
      },
      "database schemas equal"
      or diag explain $diff;
}

# TODO test upgrades

{
    my $sqlite_schema = TestDB->new();

    # rename Pgsql schema to match SQLite schema name 'main'
    $dh_schema->storage->dbh_do( sub { $_[1]->do('ALTER SCHEMA public RENAME TO main') } );

    # TODO doesn't detect constraint changes, e.g. missing UNIQUEs
    my $diff = diff_db_schema( map { $_->storage->dbh } $dh_schema, $sqlite_schema );
    cmp_deeply $diff => {
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
      },
      "database schemas equal"
      or diag explain $diff;
}

done_testing;
