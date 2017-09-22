use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Most;

#INSERT INTO 'quantities' VALUES(1,1,'Mass',2);
#INSERT INTO 'quantities' VALUES(2,1,'Volume',3);
#INSERT INTO 'units' VALUES(1,1,1,0.001,0,'g','grams');
#INSERT INTO 'units' VALUES(2,1,1,1.0,0,'kg','kilograms');
#INSERT INTO 'units' VALUES(3,1,2,1.0,0,'l','liters');
#INSERT INTO 'units' VALUES(4,1,1,1000,0,'t','tons');

my $db = TestDB->new;

my $kg = $db->resultset('Unit')->find( { short_name => 'kg' } );

my @other_units = $kg->convertible_into->all => 2, "is convertible into 2 units";

ok $kg->is_quantity_default, "unit is quantity default";

throws_ok { $kg->delete } qr/delete/, "fails while rows reference unit";

note "deleting referencing rows ...";
$db->resultset($_)->delete for qw<
  ArticleUnit
  DishIngredient
  RecipeIngredient
>;

throws_ok { $kg->delete } qr/default/, "fails because kg is default unit";

note "deleting all other units ...";
$db->resultset('Unit')->search(
    {
        short_name          => { '!=' => 'kg' },
        to_quantity_default => { '!=' => undef },
    }
)->delete;

ok $kg->delete, "default unit can be deleted if last remaining unit";

is $db->resultset('Quantity')->find( { name => 'Mass' } )->default_unit => undef,
  "default unit of quantity changed to NULL";

done_testing;
