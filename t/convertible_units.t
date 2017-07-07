use strict;
use warnings;

use DBICx::TestDatabase;
use Test::Most;

my $schema = DBICx::TestDatabase->new('Coocook::Schema');

my ( $mass, $number ) =
  $schema->resultset('Quantity')->populate( [ { name => 'Mass' }, { name => 'Number' } ] );

my ( $g, $kg, $pcs ) = my @units = $schema->resultset('Unit')->populate(
    [
        [qw<quantity space short_name long_name>],
        [ $mass->id,   0, "g",   "grams" ],
        [ $mass->id,   0, "kg",  "kilograms" ],
        [ $number->id, 0, "pcs", "pieces" ],      # not a mass!
    ]
);

my $apple = $schema->resultset('Article')->create(
    {
        name    => "Apple",
        comment => "healthy!",
    }
);

$apple->add_to_units($_) for @units;              # apple supports different quantities

my $ingredient = $schema->resultset('DishIngredient')->create(
    {
        dish    => 42,                            # doesn't exist, nobody cares
        prepare => 0,
        article => $apple->id,
        unit    => $g->id,
        value   => 42,
        comment => "more apples!",
    }
);

my @other_units = $ingredient->convertible_into();

is scalar @other_units => 1;

is $other_units[0]->short_name => "kg";    # not current unit, not unit of other quantity

done_testing;
