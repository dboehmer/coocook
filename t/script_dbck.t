use strict;
use warnings;

use lib 't/lib/';

use Coocook;
use TestDB;
use Test::Output;
use Test::Most tests => 20;

use_ok 'Coocook::Script::Dbck';

my $db = TestDB->new();

ok my $app = Coocook::Script::Dbck->new_with_options();

$app->_schema($db);

warning_is { $app->run } undef, "no warnings with test data";

{
    $db->txn_begin;

    $db->storage->dbh_do( sub { $_[1]->do('ALTER TABLE projects ADD COLUMN foobar integer') } );

    warnings_like { $app->run } [
        qr/table \W?projects\W?/,    #perldoc
        qr/<<</,
        qr/CREATE TABLE/,
        qr/---/,
        qr/CREATE TABLE/,
        qr/>>>/,
    ],
      "Error about table schema";

    $db->txn_rollback;
}

{
    $db->txn_begin;

    $db->resultset('Quantity')->find(1)->update( { project_id => 2 } );

    warnings_are { $app->run } [
        "Project IDs differ for Unit row (id = 1): me.project = 1, quantity.project = 2\n",
        "Project IDs differ for Unit row (id = 2): me.project = 1, quantity.project = 2\n",
        "Project IDs differ for Unit row (id = 4): me.project = 1, quantity.project = 2\n",
        "Project IDs differ for Unit row (id = 5): me.project = 1, quantity.project = 2\n",
    ],
      "Inconsistent project_id";

    $db->txn_rollback;
}

my $cols = do { no warnings 'once'; $Coocook::Script::Dbck::SQLITE_NOTORIOUS_EMPTY_STRING_COLUMNS }
  || die;

for my $rs ( sort keys %$cols ) {
    my @cols = map { ref ? @$_ : $_ } $cols->{$rs};

    for my $col (@cols) {
        my $table = $db->resultset($rs)->result_source->name();

        $db->txn_begin;

        # can't use DBIC update() here because Component::Result::Boolify is too good
        $db->storage->dbh_do(
            sub { $_[1]->do("UPDATE $table SET $col='' WHERE id=(SELECT id FROM $table LIMIT 1)") } );

        warning_like { $app->run } qr/column \W?$col\W? .+ empty string ''/, "$col of '' in $rs";

        $db->txn_rollback;

        if ( $col eq 'value' ) {
            $db->txn_begin;

            $db->storage->dbh_do(
                sub { $_[1]->do("UPDATE $table SET value='0,1' WHERE id=(SELECT id FROM $table LIMIT 1)") } );

            warning_like { $app->run } qr/($rs|$table) .+ number.format .+ '0,1'/x,
              "invalid number format '0,1' in $rs";

            $db->txn_rollback;
        }
    }
}

for my $table (qw< Organization User >) {
    $db->txn_begin;

    $db->resultset($table)->one_row->update( { name_fc => 'foobar' } );

    warning_like { $app->run } qr/Incorrect name_fc for $table/i, "incorrect name_fc in $table";

    $db->txn_rollback;
}

for my $col (qw< url_name url_name_fc >) {
    $db->txn_begin;

    $db->resultset('Project')->one_row->update( { $col => 'foobar' } );

    warning_like { $app->run } qr/Incorrect $col for project/, "incorrect $col in projects";

    $db->txn_rollback;
}
