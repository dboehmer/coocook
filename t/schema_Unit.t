use Test2::V0;

use lib 't/lib';
use TestDB;

plan(7);

subtest "ResultSet::Unit->in_use()" => sub {
    my $db = TestDB->new;

    is join( ',', sort $db->resultset('Unit')->in_use->get_column('short_name')->all ) => 'g,kg,l',
      "with units";

    is
      join( ',',
        sort $db->resultset('Article')->find(1)->units->in_use->get_column('short_name')->all ) => 'g,kg',
      "only units belonging to 1 article";

    is
      join( ',',
        sort $db->resultset('Article')->find(4)->units_in_use->get_column('short_name')->all ) => 'g',
      "units belonging to 1 article when not all are in use";

    $db->resultset($_)->delete for qw< DishIngredient RecipeIngredient Item >;

    is join( ',', $db->resultset('Unit')->in_use->get_column('short_name')->all ) => '',
      "without any used units";
};

my $db = TestDB->new;

my $kg = $db->resultset('Unit')->find( { short_name => 'kg' } );

is $kg->convertible_into->count => $_, "is convertible into $_ units" for 2;

ok $kg->is_quantity_default, "unit is quantity default";

like dies { $kg->delete }, qr/FOREIGN KEY constraint failed/, "fails while rows reference unit";

note "deleting referencing rows ...";
$db->resultset($_)->delete for qw<
  DishIngredient
  Item
  RecipeIngredient
  ArticleUnit
>;

like dies { $kg->delete }, qr/FOREIGN KEY constraint failed/, "fails when kg is default unit";

note "deleting all other units ...";
$kg->other_units_of_same_quantity->delete;

ok $kg->delete, "default unit can be deleted if last remaining unit";

is $db->resultset('Quantity')->find( { name => 'Mass' } )->default_unit => undef,
  "default unit of quantity changed to NULL";
