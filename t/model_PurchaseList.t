use strict;
use warnings;

use DateTime;
use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Deep;
use Test::Memory::Cycle;
use Test::MockObject;
use Test::Most;

my $db = TestDB->new;

use_ok 'Coocook::Model::PurchaseList';

my $list = new_ok 'Coocook::Model::PurchaseList',
  [ list => $db->resultset('PurchaseList')->find(1) ];

ok my $sections = $list->shop_sections;

cmp_deeply $sections => [
    superhashof(
        {
            name  => "bakery products",
            items => [
                superhashof(
                    {
                        value       => 1000,
                        unit        => superhashof( { short_name => "g" } ),
                        article     => superhashof( { name => "flour" } ),
                        ingredients => [                                       #perltidy
                            superhashof( { id => 1 } ),
                            superhashof( { id => 4 } ),
                        ],
                    }
                ),
                superhashof(
                    {
                        value       => 37.5,
                        unit        => superhashof( { short_name => "g" } ),
                        article     => superhashof( { name => "salt" } ),
                        ingredients => [                                       #perltidy
                            superhashof( { id => 6 } ),
                            superhashof( { id => 8 } ),
                        ],
                    }
                ),
            ],
        }
    ),
  ],
  "->shop_sections()"
  or explain $sections;

memory_cycle_ok $sections, "result of by_section() is free of memory cycles";

done_testing;
