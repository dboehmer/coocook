use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Most;

use_ok 'Coocook::Schema';

ok my $db = TestDB->new;

is $db->count()                   => 59, "count()";
is $db->count(qw< Article Unit >) => 11, "count(Article Unit)";

subtest statistics => sub {
    ok my $stats = $db->statistics(), "\$schema->statistics()";

    is_deeply $stats => {
        projects      => 2,
        users         => 2,
        dishes_served => 4 + 2 + 4,
    };
};

subtest fk_checks_off_do => sub {
    $db = TestDB->new;

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
      ->new_result( { project => 999, name => "shop section for bogus project" } );

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

done_testing;
