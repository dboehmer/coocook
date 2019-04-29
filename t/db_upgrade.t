use strict;
use warnings;

use Coocook::Script::Deploy;
use Coocook::Schema;
use DBICx::TestDatabase;
use Test::Most;

use lib 't/lib/';
use TestDB;

my $schema_from_deploy   = DBICx::TestDatabase->new( 'Coocook::Schema', { nodeploy => 1 } );
my $schema_from_upgrades = DBICx::TestDatabase->new( 'Coocook::Schema', { nodeploy => 1 } );
my $schema_from_code     = TestDB->new();

{
    my $app = Coocook::Script::Deploy->new( _schema => $schema_from_upgrades );

    install_ok( $app->_dh, 1 );
    upgrade_ok( $app->_dh );    # to newest version
}

{
    my $app = Coocook::Script::Deploy->new( _schema => $schema_from_deploy );

    install_ok( $app->_dh );    # newest version
}

schema_eq(
    $schema_from_deploy => $schema_from_code,
    "schema from deploy SQL and schema from Coocook::Schema code are equal"
);

schema_eq(
    $schema_from_deploy => $schema_from_upgrades,
    "schema from deploy SQL and schema from upgrade SQLs are equal"
);

done_testing;

sub install_ok {
    my ( $dh, $version, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $version
      and local *DBIx::Class::DeploymentHandler::to_version = sub { $version };

    ok $dh->install(), $name || "install version " . $dh->to_version;
}

sub upgrade_ok {
    my ( $dh, $version, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $version
      and local *DBIx::Class::DeploymentHandler::to_version = sub { $version };

    ok $dh->upgrade(), $name || "upgrade to version " . $dh->to_version;
}

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
