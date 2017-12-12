use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use TestDB;
use Test::Most;

my $db = TestDB->new;

sub article_has_items {    # value + unit->short_name joined with space: "420g 42kg"
    my ( $article, $expected, $name ) = @_;

    my @items;

    for my $item ( $article->items->search( undef, { order_by => 'short_name' } )->all ) {
        push @items, $item->value . $item->unit->short_name;
    }

    my $items = join " ", @items;

    is $items => $expected, $name || sprintf( "article %i has items '%s'", $article->id, $expected );
}

my $list            = $db->resultset('PurchaseList')->single    || die;
my $next_ingredient = $db->resultset('DishIngredient')->find(4) || die;
my $article         = $next_ingredient->article;

ok my $item = $next_ingredient->assign_to_purchase_list($list), "assign_to_purchase_list";

article_has_items $article => "500g 0.5kg";

{
    my $liters = $db->resultset('Unit')->find( { short_name => 'l' } );
    throws_ok { $item->convert($liters) } qr/quantity/;
}

my $grams = $db->resultset('Unit')->find( { short_name => 'g' } );
ok $item->convert($grams), "convert item to grams";

$next_ingredient->discard_changes;

article_has_items $article => "1000g";

ok $next_ingredient->remove_from_purchase_list, "remove_from_purchase_list";

article_has_items $article => "500g";

done_testing;
