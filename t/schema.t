use Test2::V0;

use Coocook::Schema;

use lib 't/lib';
use TestDB;

plan(8);

ok my $db = TestDB->new;

is $db->count()                   => 76, "count()";
is $db->count(qw< Article Unit >) => 11, "count(Article Unit)";

subtest "one_row() in favor of first()" => sub {
    my $__FILE__ = __FILE__;
    my $rs       = $db->resultset('Project');

    like dies { $rs->first() }, qr/ one_row .+ \Q$__FILE__\E /x,
      "first() fails, recommends one_row() and names correct source file";

    isa_ok $rs->one_row() => ['DBIx::Class::Row'], "one_row() returns Result object";
};

subtest statistics => sub {
    ok my $stats = $db->statistics(), "\$schema->statistics()";

    is $stats => hash {
        field public_projects => 1;
        field users           => 2;
        field organizations   => 1;
        field recipes         => 2;
        field dishes_served   => 4 + 2 + 4;
        field dishes_planned  => 0;
        etc();
    };
};

# method is overwritten and should still support all argument types
subtest connection => sub {
    my %dbi_attributes   = ( AutoCommit    => 1 );
    my %extra_attributes = ( on_connect_do => 'SELECT 1' );

    # same order as in https://metacpan.org/pod/DBIx::Class::Storage::DBI#connect_info
    ok(
        Coocook::Schema->connect(
            'dbi:SQLite::memory:', 'user', 'password', \%dbi_attributes, \%extra_attributes
        )
    );

    ok(
        Coocook::Schema->connect(
            sub { DBI->connect( 'dbi:SQLite::memory:', 'user', 'password', \%dbi_attributes ) },
            \%extra_attributes
        )
    );

    ok(
        Coocook::Schema->connect(
            {
                dsn      => 'dbi:SQLite::memory:',
                user     => 'user',
                password => 'password',
                %dbi_attributes,
                %extra_attributes
            }
        )
    );

    ok(
        Coocook::Schema->connect(
            {
                dbh_maker => sub { DBI->connect('dbi:SQLite::memory:') },
                %dbi_attributes,
                %extra_attributes
            }
        )
    );

    my $dbh = DBI->connect( 'dbi:SQLite::memory:', undef, undef, { RaiseError => 1 } );
    $dbh->do('CREATE TABLE tests ( "type" text )');

    my $code_was_run;

    # same order as https://metacpan.org/pod/DBIx::Class::Storage::DBI#on_connect_do
    #
    # variant 4 is documented as [sub {'...'}] but DBIC only actually implements sub [sub {['...']}]
    my @on_connect_do = (
        undef,
        "INSERT INTO tests VALUES( 'string' )",
        ["INSERT INTO tests VALUES( 'string in arrayref' )"],
        [ sub { ["INSERT INTO tests VALUES( 'coderef in arrayref' )"] } ],
        sub { $code_was_run++; return 'DBIC will ignore this' },
    );

    for my $on_connect_do (@on_connect_do) {
        ok my $schema = Coocook::Schema->connect( sub { $dbh }, { on_connect_do => $on_connect_do } ),
          "Coocook::Schema->connect()";

        ok $schema->storage->dbh->ping, "trigger DBIx-Class to actually connect";

        ok $schema->sqlite_pragma('foreign_keys'), "PRAGMA foreign_keys is enabled by default";
    }

    is $dbh->selectrow_array('SELECT COUNT() FROM tests') => $_, "$_ entries" for 3;
    ok $code_was_run, "code in single coderef was executed";
};

subtest fk_checks_off_do => sub {
    $db = TestDB->new;

    $db->fk_checks_off_do(
        sub {
            ok !$db->sqlite_pragma('foreign_keys'), "PRAGMA foreign_keys is disabled by fk_checks_off_do()";
        }
    );

    ok $db->sqlite_pragma('foreign_keys'), "PRAGMA foreign_keys is enabled after fk_checks_off_do()";

    ok $db->sqlite_pragma( foreign_keys => 0 ), "disable PRAGMA foreign_keys";
    ok !$db->sqlite_pragma('foreign_keys'),     "... PRAGMA foreign_keys is disabled";

    ok $db->sqlite_pragma( foreign_keys => 1 ), "enable PRAGMA foreign_keys";
    ok $db->sqlite_pragma('foreign_keys'),      "... PRAGMA foreign_keys is enabled";

    $db->fk_checks_off_do( sub { is join( '', @_ ) => 'abc', "fk_checks_off_do() passes args" },
        'a' .. 'c' );

    is $db->fk_checks_off_do( sub { return 'foo' } ) => 'foo', "fk_checks_off_do() passes return value";

    {
        no warnings 'once', 'redefine';
        local *DBIx::Class::Storage::DBI::sqlt_type = sub { 'OtherDBMS' };
        like dies {
            $db->fk_checks_off_do( sub { } )
        }, qr/SQLite/, "SQLite check";
    }

    my $row =
      $db->resultset('ShopSection')
      ->new_result( { project_id => 999, name => "shop section for bogus project" } );

    ok lives {
        $db->fk_checks_off_do(
            sub {
                $row->insert();
                $row->delete();
            }
        );
    }, "inserting and deleting invalid FK works inside fk_checks_off_do";

    like dies { $row->insert }, qr/FOREIGN KEY constraint failed/, "inserting doesn't work outside";

    todo "How to enforce checks when re-enabling 'foreign_keys' pragma?" => sub {
        like dies {
            $db->fk_checks_off_do( sub { $row->insert() } )
        }, qr/some error/, "throws error at end of fk_checks_off_do after insert";    # TODO error message
    };
};

subtest assert_no_sth => sub {
    $db = TestDB->new;
    my $projects = $db->resultset('Project');

    ok lives { $projects->assert_no_sth }, "Passes before next()";
    ok $projects->next,                    "Call next()";
    like dies { $projects->assert_no_sth }, qr/Statement/, "Fails after next()";
};
