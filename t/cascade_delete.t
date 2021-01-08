use lib 't/lib';

use DateTime;
use TestDB;
use Test::Most;

my $db = TestDB->new;

subtest "Dish->delete" => sub {
    ok $db->resultset('Dish')->delete, "delete()";

    is $db->resultset('DishIngredient')->count => 0,
      "also deleted dish_ingredients";
};

subtest "Recipe->delete" => sub {
    ok $db->resultset('Recipe')->delete, "delete()";

    is $db->resultset('RecipeIngredient')->count => 0,
      "also deleted recipe_ingredients";
};

done_testing;
