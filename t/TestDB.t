use Test2::V0;

use lib 't/lib';
use TestDB qw(install_ok upgrade_ok);

ok my $db = TestDB->new, "TestDB->new";

ok $db->count, "deployed";

ok my $db2 = TestDB->new, "another instance";

ok $db2->count, "... is also populated";

# rows from 'dish_ingredients' can be safely deleted because no FK point there
ok $db->resultset('DishIngredient')->delete, "delete table in 1st instance";

ok $db2->resultset('DishIngredient')->count, "table still populated in 2nd instance";

is intercept(
    sub {
        ok lives { install_ok( $db, -1 ) }
    }
)->squash_info->flatten => array {
    item hash {
        field pass       => 0;
        field trace_file => __FILE__;
        field trace_line => __LINE__ - 5;
        etc();
    };
};

is intercept(
    sub {
        ok lives { upgrade_ok( $db, -1 ) }
    }
)->squash_info->flatten => array {
    item hash {
        field pass       => 0;
        field trace_file => __FILE__;
        field trace_line => __LINE__ - 5;
        etc();
    };

};

done_testing;
