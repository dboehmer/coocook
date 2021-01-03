use strict;
use warnings;

use Test2::Require::Module 'Test::PostgreSQL';
use Test2::Require::Module 'DateTime::Format::Pg';

use Coocook::Script::Deploy;
use Coocook::Schema;
use DBIx::Diff::Schema qw(diff_db_schema);
use Test::Deep;
use Test::Most;

use lib 't/lib';
use TestDB qw(install_ok upgrade_ok);
use Test::Coocook;

my $FIRST_PGSQL_SCHEMA_VERSION = 21;

plan tests => 2 + 3 * ( $Coocook::Schema::VERSION - $FIRST_PGSQL_SCHEMA_VERSION ) + 7;

my $pg_dbic          = Test::PostgreSQL->new();
my $schema_from_dbic = Coocook::Schema->connect( $pg_dbic->dsn );
lives_ok { $schema_from_dbic->deploy() } "deploy with DBIx::Class";

my $pg_deploy          = Test::PostgreSQL->new();
my $schema_from_deploy = Coocook::Schema->connect( $pg_deploy->dsn );

my $pg_upgrades          = Test::PostgreSQL->new();
my $schema_from_upgrades = Coocook::Schema->connect( $pg_upgrades->dsn );
install_ok( $schema_from_upgrades, $FIRST_PGSQL_SCHEMA_VERSION );

for my $version ( $FIRST_PGSQL_SCHEMA_VERSION + 1 .. $Coocook::Schema::VERSION ) {
    $pg_deploy          = Test::PostgreSQL->new();
    $schema_from_deploy = Coocook::Schema->connect( $pg_deploy->dsn );
    install_ok( $schema_from_deploy, $version );

    upgrade_ok( $schema_from_upgrades, $version );

    schema_diff_like( $schema_from_upgrades, $schema_from_deploy, {},
        "schema version $version from upgrade SQLs and schema from deploy SQL are equal" );
}

# share/test_data.sql matches only current schema -> can only after upgrades
ok( TestDB->execute_test_data($schema_from_dbic),     "Execute test data in DB from DBIx::Class" );
ok( TestDB->execute_test_data($schema_from_deploy),   "Execute test data in DB from deploy SQL" );
ok( TestDB->execute_test_data($schema_from_upgrades), "Execute test data in DB from upgrade SQLs" );

note "Fixing Pgsql sequences after bulk insert";
for my $source ( $schema_from_dbic->sources ) {
    $source eq 'Session'    # this table has string id column
      and next;

    my $result_source = $schema_from_dbic->resultset($source)->result_source;

    if ( $result_source->has_column('id') ) {
        my $table = $result_source->name;

        $schema_from_dbic->storage->dbh_do(
            sub {
                $_[1]->do(<<SQL) } );
SELECT setval('${table}_id_seq', (SELECT MAX(id) FROM $table), true)
SQL
    }
}

subtest "boolean values" => sub {
    my $row = $schema_from_dbic->resultset('Project')->one_row;
    my $col = 'is_public';

    like $row->get_column($col) => qr/^[01]$/, "DBD::Pg returns 0 or 1";

    ok $row->update( { $col => $_ } ), "SET $col = $_" for 0, 1;
    ok $row->update( { $col => '' } ), "SET $col = ''";
};

my $sqlite_schema = TestDB->new();

subtest "deleting projects" => sub {
    my $t = Test::Coocook->new( schema => $schema_from_dbic );
    $t->get_ok('/');
    $t->login_ok( 'john_doe', 'P@ssw0rd' );
    $t->get_ok('https://localhost/project/1/Test-Project/settings');

    $t->submit_form_ok( { form_name => 'delete', with_fields => { confirmation => 'Test Project' } },
        "delete project" );

    is $schema_from_dbic->resultset('Project')->find(1) => undef, "project has vanished";
};

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
                  recipes_of_the_day
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

# most important finding: CURRENT_TIMESTAMP is UTC in SQLite but local timezone in PostgreSQL
subtest "timestamps are stored in UTC" => sub {
    my $schema = $schema_from_dbic;

    # with Test::PostgreSQL the default timezone is UTC which makes bugs unnoticeable
    $schema->storage->dbh_do(
        sub {
            $_[1]->do("SET TIME ZONE 'Pacific/Chatham'");    # weird timezone UTC+12:45
        }
    );

    my $t = Test::Coocook->new(
        config => { enable_user_registration => 1 },
        schema => $schema,
    );

    $t->get_ok('/');
    $t->register_ok( { username => 'u', email => 'u@example.com', password => 'p', password2 => 'p' } );
    $t->get_ok_email_link_like(qr/verify/);
    $t->clear_emails();
    $t->submit_form_ok( { with_fields => { password => 'p' } } );

    my $utc_hour  = sprintf '%02i', (gmtime)[2];    # gmtime() provides UTC and calls it "GMT"
    my $utc_regex = qr/ $utc_hour:..:../;

    my $user = $schema->resultset('User')->find( { name_fc => 'u' } );
    like $user->get_column('email_verified') => $utc_regex, "column 'email_verified' is in UTC";

    $t->request_recovery_link_ok('u@example.com');
    $user->discard_changes();
    like( $user->get_column($_) => $utc_regex, "column '$_' is in UTC" )
      for qw< token_created token_expires >;

    ok $user->update( { map { $_ => undef } qw< token_created token_expires > } ),
      "set columns NULL to avoid false positives";

    $t->follow_link_ok( { text        => 'settings Settings' } );
    $t->submit_form_ok( { with_fields => { new_email => 'x@example.com' } } );
    $user->discard_changes();
    like( $user->get_column($_) => $utc_regex, "column '$_' is in UTC" )
      for qw< token_created token_expires >;

    $t->get_ok('/');
    $t->submit_form_ok( { with_fields => { name => 'Project UTC' } }, "create project" );
    $t->follow_link_ok( { text        => 'Project' } );
    $t->follow_link_ok( { text        => 'Settings' } );
    note $t->content;
    $t->submit_form_ok( { with_fields => { archive => 'on' } } );
    my $project = $schema->resultset('Project')->find( { name => 'Project UTC' } ) || die;
    like( $project->get_column($_) => $utc_regex, "column '$_' is in UTC" ) for qw< created archived >;
};

sub schema_diff_like {
    my ( $schema1, $schema2, $expected_diff, $name ) = @_;

    # TODO doesn't detect constraint changes, e.g. missing UNIQUEs
    my $diff = diff_db_schema( map { $_->storage->dbh } $schema1, $schema2 );

    cmp_deeply $diff => $expected_diff,
      $name // "database schemas equal"
      or diag explain $diff;
}
