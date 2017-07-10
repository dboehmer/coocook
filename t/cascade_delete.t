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

my $dish = $meal->create_related(
    dishes => {
        name        => "Bratwurst & Sauerkraut",
        servings    => 2,
        preparation => "",
        description => "",
        comment     => "Yummie!"
    }
);

$dish->create_related(
    ingredients => {
        prepare => 0,
        article => $article,
        unit    => $kg,
        value   => 42,
        comment => "most important ingredient"
    }
);

is $schema->resultset('DishIngredient')->count => 1, "has dish_ingredients";

$dish->delete;

is $schema->resultset('DishIngredient')->count => 0, "deleted all dish_ingredients";

done_testing;
