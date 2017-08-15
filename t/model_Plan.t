use strict;
use warnings;

use DateTime;
use DBICx::TestDatabase;
use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::MockObject;
use Test::Most;

my $db = TestDB->new;

use_ok 'Coocook::Model::Plan';

my $plan = new_ok 'Coocook::Model::Plan', [ schema => $db ];

# TODO test COMPONENT()

my $day = $plan->day( DateTime->new( year => 2000, month => 1, day => 1 ) );
is_deeply $day => [
    {
        'dishes' => [
            {
                'description' => 'Make them really sweet!',
                'id'          => 1,
                'ingredients' => [
                    {
                        'article' => {
                            'comment' => '',
                            'name'    => 'flour'
                        },
                        'comment' => '',
                        'prepare' => 0,
                        'unit'    => {
                            'long_name'  => 'grams',
                            'short_name' => 'g'
                        },
                        'value' => '500'
                    },
                    {
                        'article' => {
                            'comment' => '',
                            'name'    => 'salt'
                        },
                        'comment' => '',
                        'prepare' => 0,
                        'unit'    => {
                            'long_name'  => 'grams',
                            'short_name' => 'g'
                        },
                        'value' => '5'
                    },
                    {
                        'article' => {
                            'comment' => '',
                            'name'    => 'water'
                        },
                        'comment' => '',
                        'prepare' => 0,
                        'unit'    => {
                            'long_name'  => 'liters',
                            'short_name' => 'l'
                        },
                        'value' => '0.5'
                    }
                ],
                'name'        => 'pancakes',
                'preparation' => '',
                'servings'    => 4
            }
        ],
        'name'            => 'breakfast',
        'prepared_dishes' => []
    }
  ],
  "day()"
  or explain $day;

my $project = $plan->project(1);
$_->{date} .= "" for @$project;    # stringify dates for simpler comparison
is_deeply $project => [
    {
        'date'  => '2000-01-01T00:00:00',
        'meals' => [
            {
                'dishes' => ['pancakes'],
                'name'   => 'breakfast'
            }
        ]
    },
    {
        'date'  => '2000-01-02T00:00:00',
        'meals' => [
            {
                'dishes' => ['pizza'],
                'name'   => 'lunch'
            }
        ]
    },
    {
        'date'  => '2000-01-03T00:00:00',
        'meals' => [
            {
                'dishes' => ['bread'],
                'name'   => 'dinner'
            }
        ]
    }
  ],
  "project()"
  or explain $project;

done_testing;
