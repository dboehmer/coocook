use strict;
use warnings;

use DateTime;
use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Most;

my $db = TestDB->new;

subtest "Dish->delete" => sub {
    my $a = count('DishIngredient');
    ok $db->resultset('Dish')->first->delete, "delete()";
    my $b = count('DishIngredient');

    cmp_ok $a, '>', $b, "also deleted dish_ingredients";
};

subtest "Recipe->delete" => sub {
    my $a = count('RecipeIngredient');
    ok $db->resultset('Recipe')->first->delete, "delete()";
    my $b = count('RecipeIngredient');

    cmp_ok $a, '>', $b, "also deleted recipe_ingredients";
};

done_testing;

sub count {
    my $rs = shift;

    return $db->resultset($rs)->count;
}
