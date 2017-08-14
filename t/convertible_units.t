use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Most;

my $db = TestDB->new;

my $ingredient = $db->resultset('RecipeIngredient')->find(1);

my @other_units = $ingredient->convertible_into->all;

my @article_units = $ingredient->article->units->all;

my @quantity_units = $ingredient->unit->quantity->units->all;

note "ingredient.unit: " . $ingredient->unit->short_name;
note "article_units: " . join ", " => map { $_->short_name } @article_units;
note "quantity_units: " . join "," => map { $_->short_name } @quantity_units;
note "other_units: " . join ","    => map { $_->short_name } @other_units;

ok @other_units + 1 == @article_units;

ok @article_units < @quantity_units;

done_testing;
