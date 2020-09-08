use strict;
use warnings;

use lib 't/lib/';

use TestDB;
use Test::Most tests => 8;

my $schema = TestDB->new();

use_ok 'Coocook::Model::Ingredients';

my $ingredients = new_ok 'Coocook::Model::Ingredients',
  [ recipe => $schema->resultset('Recipe')->find(1) ],
  "ingredients from recipe";

cmp_deeply $ingredients->as_arrayref => [
    superhashof(
        { value => 0.5, unit => methods( short_name => 'l' ), article => methods( name => 'water' ) }
    ),
    superhashof(
        { value => 1, unit => methods( short_name => 'kg' ), article => methods( name => 'flour' ) }
    ),
    superhashof(
        { value => 15, unit => methods( short_name => 'g' ), article => methods( name => 'salt' ) }
    ),
    superhashof(
        {
            value   => 10,
            unit    => methods( short_name => 'g' ),
            article => methods( name       => 'salt' ),
            comment => 'if you like salty'
        }
    ),
  ],
  "as_arrayref()";

ok $ingredients->factor(42), "set factor";

cmp_deeply $ingredients->as_arrayref => [
    superhashof( { value => 21 } ),
    superhashof( { value => 42 } ),
    superhashof( { value => 630 } ),
    superhashof( { value => 420 } ),
  ],
  "multiplied values";

cmp_deeply my $articles = $ingredients->all_articles => [
    listmethods(
        name  => ['cheese'],
        units => [ methods( short_name => 'g' ), methods( short_name => 'kg' ) ]
    ),
    listmethods(
        name  => ['flour'],
        units => [ methods( short_name => 'g' ), methods( short_name => 'kg' ) ]
    ),
    listmethods( name => ['love'],  units => [] ),
    listmethods( name => ['salt'],  units => [ methods( short_name => 'g' ) ] ),
    listmethods( name => ['water'], units => [ methods( short_name => 'l' ) ] ),
  ],
  "all_articles";

{
    local $TODO = "fetch objects only once";
    cmp_deeply(
        ( $articles->[0]->units )[0] => shallow( ( $articles->[1]->units )[1] ),
        "kg of cheese and kg of flour are the same Result object"
    );
}

cmp_deeply my $units = $ingredients->all_units => [
    methods( short_name => 'g',  long_name => 'grams' ),
    methods( short_name => 'kg', long_name => 'kilograms' ),
    methods( short_name => 'l',  long_name => 'liters' ),
  ],
  "all_units";
