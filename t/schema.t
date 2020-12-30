use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Most;

use_ok 'Coocook::Schema';

ok my $db = TestDB->new;

is $db->count()                   => 76, "count()";
is $db->count(qw< Article Unit >) => 11, "count(Article Unit)";

subtest "one_row() in favor of first()" => sub {
    my $__FILE__ = __FILE__;
    my $rs       = $db->resultset('Project');

    throws_ok { $rs->first() } qr/ one_row .+ \Q$__FILE__\E /x,
      "first() fails, recommends one_row() and names correct source file";

    isa_ok $rs->one_row() => 'DBIx::Class::Row', "one_row() returns Result object";
};

subtest statistics => sub {
    ok my $stats = $db->statistics(), "\$schema->statistics()";

    cmp_deeply $stats => superhashof {
        public_projects => 1,
        users           => 2,
        organizations   => 1,
        recipes         => 2,
        dishes_served   => 4 + 2 + 4,
        dishes_planned  => 0,
    };
};

subtest fk_checks_off_do => sub {
    $db = TestDB->new;

    ok $db->sqlite_pragma('foreign_keys'), "PRAGMA foreign_keys is enabled by default";

    $db->fk_checks_off_do(
        sub {
            ok !$db->sqlite_pragma('foreign_keys'), "PRAGMA foreign_keys is disabled by fk_checks_off_do()";
        }
    );

    ok $db->sqlite_pragma('foreign_keys'), "PRAGMA foreign_keys is enabled after fk_checks_off_do()";

    ok $db->sqlite_pragma( foreign_keys => 0 ), "disable PRAGMA foreign_keys";
    ok !$db->sqlite_pragma('foreign_keys'), "... PRAGMA foreign_keys is disabled";

    ok $db->sqlite_pragma( foreign_keys => 1 ), "enable PRAGMA foreign_keys";
    ok $db->sqlite_pragma('foreign_keys'), "... PRAGMA foreign_keys is enabled";

    $db->fk_checks_off_do( sub { is join( '', @_ ) => 'abc', "fk_checks_off_do() passes args" },
        'a' .. 'c' );

    is $db->fk_checks_off_do( sub { return 'foo' } ) => 'foo', "fk_checks_off_do() passes return value";

    {
        no warnings 'once', 'redefine';
        local *DBIx::Class::Storage::DBI::sqlt_type = sub { 'OtherDBMS' };
        throws_ok {
            $db->fk_checks_off_do( sub { } )
        }
        qr/SQLite/, "SQLite check";
    }

    my $row =
      $db->resultset('ShopSection')
      ->new_result( { project_id => 999, name => "shop section for bogus project" } );

    lives_ok {
        $db->fk_checks_off_do(
            sub {
                $row->insert();
                $row->delete();
            }
        );
    }
    "inserting and deleting invalid FK works inside fk_checks_off_do";

    throws_ok { $row->insert } qr/FOREIGN KEY constraint failed/, "inserting doesn't work outside";

    local $TODO = "How to enforce checks when re-enabling 'foreign_keys' pragma?";
    throws_ok {
        $db->fk_checks_off_do( sub { $row->insert() } )
    }
    qr/some error/, "throws error at end of fk_checks_off_do after insert";    # TODO error message
};

subtest assert_no_sth => sub {
    $db = TestDB->new;
    my $projects = $db->resultset('Project');

    lives_ok { $projects->assert_no_sth } "Passes before next()";
    ok $projects->next, "Call next()";
    throws_ok { $projects->assert_no_sth } qr/Statement/, "Fails after next()";
};

done_testing;
