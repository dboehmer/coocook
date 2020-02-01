use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use TestDB;
use Test::Most;

my $db = TestDB->new;

sub article_has_items {    # value + unit->short_name joined with space: "420g 42kg"
    my ( $article, $expected, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @items;

    for my $item ( $article->items->search( undef, { order_by => 'short_name' } )->all ) {
        push @items, $item->value . $item->unit->short_name;
    }

    my $items = join " ", @items;

    is $items => $expected,
      $name || sprintf( "article %i '%s' has items '%s'", $article->id, $article->name, $expected );
}

my $list              = $db->resultset('PurchaseList')->find(1)    || die;
my $next_ingredient   = $db->resultset('DishIngredient')->find(7)  || die;
my $delete_ingredient = $db->resultset('DishIngredient')->find(11) || die;
my $flour             = $db->resultset('Article')->find(1)         || die;

article_has_items $flour => "1000g";

ok my $item = $next_ingredient->assign_to_purchase_list($list), "assign_to_purchase_list";

article_has_items $flour => "1000g 1kg";

{
    my $liters = $db->resultset('Unit')->find( { short_name => 'l' } );
    throws_ok { $item->convert($liters) } qr/quantity/;
}

my $grams = $db->resultset('Unit')->find( { short_name => 'g' } );
ok $item->convert($grams), "convert item to grams";

article_has_items $flour => "2000g";

$next_ingredient->discard_changes;

ok $next_ingredient->remove_from_purchase_list, "DishIngredient->remove_from_purchase_list";

article_has_items $flour => "1000g";

ok $item = $delete_ingredient->assign_to_purchase_list($list),
  "assign_to_purchase_list (different units)";

article_has_items $flour => "1000g 12.5kg";

ok $item->convert($grams), "convert item to grams";

article_has_items $flour => "13500g";

$delete_ingredient->discard_changes;

ok $delete_ingredient->remove_from_purchase_list,
  "DishIngredient->remove_from_purchase_list (different units)";

article_has_items $flour => "1000g";

done_testing;
