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
    {
        id      => 1,
        project => 1,
        name    => 'bakery products',
        items   => [
            {
                id            => 1,
                comment       => '',
                purchase_list => 1,
                purchased     => 0,
                value         => 500,
                offset        => 0.0,
                unit          => {
                    can_be_quantity_default => 1,
                    id                      => 1,
                    long_name               => 'grams',
                    project                 => 1,
                    quantity                => 1,
                    short_name              => 'g',
                    space                   => 0,
                    to_quantity_default     => 0.001,
                    convertible_into        => [ ignore, ignore ],
                },
                article => {
                    id                  => 1,
                    name                => 'flour',
                    comment             => '',
                    project             => 1,
                    shop_section        => 1,
                    'preorder_servings' => undef,
                    preorder_workdays   => undef,
                    shelf_life_days     => undef,
                },
                ingredients => [
                    {
                        id       => 1,
                        comment  => '',
                        item     => 1,
                        position => 1,
                        prepare  => 0,
                        value    => 500,
                        unit     => ignore,
                        article  => ignore,
                        dish     => {
                            id              => 1,
                            comment         => '',
                            description     => 'Make them really sweet!',
                            from_recipe     => undef,
                            meal            => 1,
                            name            => 'pancakes',
                            preparation     => '',
                            prepare_at_meal => undef,
                            servings        => 4
                        },
                    },
                    ignore,
                ],
            },
        ],
    },
  ],
  "by_section()"
  or explain $sections;

memory_cycle_ok $sections, "result of by_section() is free of memory cycles";

done_testing;
