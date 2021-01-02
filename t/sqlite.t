use strict;
use warnings;

use Coocook::Schema;
use Test::Most;

use lib 't/lib/';
use TestDB qw(install_ok upgrade_ok);

# first upgrade scripts created columns in different order
# or had other subtle differences to a fresh deployment
#
# share/ddl/SQLite/upgrade/12-13/fix-cascade.sql is the
# first upgrade script that has an equal result
#
# earlier upgrade scripts should NOT be fixed because
# deployments from these versions stay the same and
# will be fixed with upgrade to version 13. Luckily
# we are pretty sure there are no installations
# older than version 13.
my %SCHEMA_VERSIONS_WITH_DIFFERENCES = map { $_ => 1 } ( 3 .. 5, 7 .. 12 );

plan tests => 1 + 3 * ( $Coocook::Schema::VERSION - 1 ) + 2;

my $schema_from_code = TestDB->new();
my $schema_from_deploy;
my $schema_from_upgrades = TestDB->new( deploy => 0 );

install_ok( $schema_from_upgrades, 1 );

# generated upgrade scripts contain
# CREATE TEMPORARY TABLE ... with FKs on main tables which is impossible
# http://sqlite.1065341.n5.nabble.com/Foreign-keys-amp-TEMPORARY-tables-td92306.html
diag "TODO disabling PRAGMA foreign_keys on DB from upgrade SQLs";
$schema_from_upgrades->disable_fk_checks();

for my $version ( 2 .. $Coocook::Schema::VERSION ) {
    $schema_from_deploy = TestDB->new( deploy => 0 );
    install_ok( $schema_from_deploy, $version );

    upgrade_ok( $schema_from_upgrades, $version );

  SKIP: {
        $SCHEMA_VERSIONS_WITH_DIFFERENCES{$version}
          and skip "Upgrade SQL files are known to be broken", 1;

        schema_eq(
            $schema_from_upgrades => $schema_from_deploy,
            "schema version $version from upgrade SQLs and schema from deploy SQL are equal"
        );
    }
}

schema_eq(
    $schema_from_deploy => $schema_from_code,
    "schema from deploy SQL and schema from Coocook::Schema code are equal"
);

schema_eq(
    $schema_from_upgrades => $schema_from_code,
    "schema from upgrade SQLs and schema from Coocook::Schema code are equal"
);

sub schema_eq {
    my ( $schema1, $schema2, $test_name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $test_name => sub {
        my @schemas = (
            my $a = { id => 1, dbh => $schema1->storage->dbh },
            my $b = { id => 2, dbh => $schema2->storage->dbh },
        );

        my %table_names;

        for my $schema (@schemas) {
            my $sth = $schema->{dbh}->table_info( undef, undef, '%' );

            while ( my $table = $sth->fetchrow_hashref ) {
                ##note explain $table;

                my $type = $table->{TABLE_TYPE};
                my $name = $table->{TABLE_NAME};
                my $sql  = $table->{sqlite_sql};

                if ( $type eq 'SYSTEM TABLE' ) { next }

                $schema->{tables}{$name} = $sql;

                $table_names{$name}++;
            }
        }

      NAME: for my $name ( keys %table_names ) {
            next if $name eq 'dbix_class_deploymenthandler_versions';    # ignore internal table

            for my $schema (@schemas) {
                if ( not exists $schema->{tables}{$name} ) {
                    fail $name;
                    diag "Table '$name' is missing in schema " . $schema->{id};
                    next NAME;
                }
            }

            my $sql1 = $a->{tables}{$name};
            my $sql2 = $b->{tables}{$name};

            for ( $sql1, $sql2 ) {
                defined or next;

                s/\s+/ /gs;    # ignore whitespace differences
                s/['"]//g;     # ignore quote characters
            }

            is $sql1 => $sql2, $name;
        }
    };
}
