use strict;
use warnings;

use DateTime;
use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::MockObject;
use Test::Most;

my $db = TestDB->new;

my $project = $db->resultset('Project')->find(1);

use_ok 'Coocook::Model::Plan';

my $plan = new_ok 'Coocook::Model::Plan', [ schema => $db ];

my $day = $plan->day( $project, DateTime->new( year => 2000, month => 1, day => 1 ) );
is_deeply $day => [
    {
        name            => 'breakfast',
        comment         => "Best meal of the day!",
        prepared_dishes => [],
        dishes          => [
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
    }
  ],
  "day()"
  or explain $day;

my $project_plan = $plan->project($project);
$_->{date} .= "" for @$project_plan;    # stringify dates for simpler comparison
is_deeply $project_plan => [
    {
        'date'  => '2000-01-01T00:00:00',
        'meals' => [
            {
                'dishes' => [ { id => 1, name => 'pancakes', servings => 4 } ],
                'name'   => 'breakfast'
            }
        ]
    },
    {
        'date'  => '2000-01-02T00:00:00',
        'meals' => [
            {
                'dishes' => [ { id => 2, name => 'pizza', servings => 4 } ],
                'name'   => 'lunch'
            }
        ]
    },
    {
        'date'  => '2000-01-03T00:00:00',
        'meals' => [
            {
                'dishes' => [ { id => 3, name => 'bread', servings => 4 } ],
                'name'   => 'dinner'
            }
        ]
    }
  ],
  "project()"
  or explain $project_plan;

done_testing;
