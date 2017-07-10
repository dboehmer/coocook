use strict;
use warnings;

use DateTime;
use DBICx::TestDatabase;
use Test::Most;

my $schema = DBICx::TestDatabase->new('Coocook::Schema');

my $mass = $schema->resultset('Quantity')->create( { name => "Mass" } );
my $kg =
  $mass->create_related( units => { short_name => "kg", long_name => "kilograms", space => 0 } );

my $article =
  $schema->resultset('Article')->create( { name => "Sauerkraut", comment => "best of Germany" } );

my $project = $schema->resultset('Project')->create( { name => "Foo" } );

my $meal = $project->create_related(
    meals => {
        date    => DateTime->today->ymd,
        name    => "Dinner",
        comment => "with candle light for two"
    }
);

my $recipe = $schema->resultset('Recipe')->create(
    {
        name        => "Bratwurst & Sauerkraut",
        servings    => 2,
        preparation => "",
        description => "",
    }
);

$recipe->create_related(
    ingredients => {
        prepare => 0,
        article => $article,
        unit    => $kg,
        value   => 42,
        comment => "most important ingredient"
    }
);

my $dish = $schema->resultset('Dish')->from_recipe(
    $recipe,
    (
        meal    => $meal,
        comment => "Yummie!",
    )
);

subtest "Dish->delete" => sub {
    is $schema->resultset('DishIngredient')->count => 1, "has dish_ingredients";

    $dish->delete;

    is $schema->resultset('DishIngredient')->count => 0, "deleted all dish_ingredients";
};

subtest "Recipe->delete" => sub {
    is $schema->resultset('RecipeIngredient')->count => 1, "has recipe_ingredients";

    $recipe->delete;

    is $schema->resultset('RecipeIngredient')->count => 0, "deleted all recipe_ingredients";
};

done_testing;
