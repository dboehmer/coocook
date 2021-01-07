use strict;
use warnings;
use lib 't/lib';

use Test::Coocook;
use Test::Most;

my $t = Test::Coocook->new();

$t->get_ok('/');
$t->text_unlike(qr/recipes? of the day/i);

my $rotd    = $t->schema->resultset('RecipeOfTheDay');
my $recipes = $t->schema->resultset('Recipe');
my $public  = $recipes->public;

# another recipe available for picking
$recipes->create(
    { project_id => 1, name => __FILE__, servings => 42, description => '', preparation => '' } );

my ( $recipe1, $recipe2 ) = $public->all;

$rotd->create(
    {
        day       => $rotd->format_date_today,
        recipe_id => $recipe1->id,
    }
);

$t->reload_ok();
$t->text_like(qr/recipe of the day/i);
$t->text_contains( $recipe1->name );

$t->follow_link_ok( { text => $recipe1->name } );
$t->base_like(qr{ localhost/recipe/\d+/\w+ }x);

$t->reload_config( { pick_recipes_of_the_day => 1000 } );
$t->get_ok('/');
$t->text_like(qr/recipes of the day/i);
$t->text_contains( $recipe2->name );

is $rotd->count => $public, "picked as many recipes as there public ones";

done_testing;
