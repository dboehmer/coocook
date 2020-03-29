use strict;
use warnings;

use DateTime;
use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Memory::Cycle;
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
                'id'          => 1,
                'name'        => 'pancakes',
                'comment'     => '',
                'servings'    => 4,
                'preparation' => '',
                'description' => 'Make them really sweet!',
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
            }
        ],
    }
  ],
  "day()"
  or explain $day;

memory_cycle_ok $day;

my $expected = [
    {
        date  => '2000-01-01T00:00:00',
        meals => [
            {
                id         => 1,
                project_id => 1,
                date       => '2000-01-01T00:00:00',
                name       => 'breakfast',
                dishes     => [
                    {
                        id                 => 1,
                        prepare_at_meal_id => undef,
                        from_recipe_id     => undef,
                        name               => 'pancakes',
                        preparation        => '',
                        description        => 'Make them really sweet!',
                        comment            => '',
                        servings           => 4
                    }
                ],
                prepared_dishes => [],
                comment         => 'Best meal of the day!',
            }
        ]
    },
    {
        date  => '2000-01-02T00:00:00',
        meals => [
            {
                id         => 2,
                project_id => 1,
                date       => '2000-01-02T00:00:00',
                name       => 'lunch',
                dishes     => [
                    {
                        id                 => 2,
                        prepare_at_meal_id => undef,
                        from_recipe_id     => 1,
                        name               => 'pizza',
                        preparation        => '',
                        description        => '',
                        comment            => '',
                        servings           => 2
                    }
                ],
                prepared_dishes => '!!! this should become an arrayref before is_deeply() !!!',
                comment         => '',
            }
        ]
    },
    {
        date  => '2000-01-03T00:00:00',
        meals => [
            {
                id         => 3,
                project_id => 1,
                date       => '2000-01-03T00:00:00',
                name       => 'dinner',
                dishes     => [
                    {
                        id                 => 3,
                        prepare_at_meal_id => 2,
                        from_recipe_id     => undef,
                        name               => 'bread',
                        preparation        => 'Bake bread!',
                        description        => '',
                        comment            => '',
                        servings           => 4
                    }
                ],
                prepared_dishes => [],
                comment         => '',
            }
        ]
    }
];
$expected->[1]{meals}[0]{prepared_dishes} = [ $expected->[2]{meals}[0]{dishes}[0] ];

for (@$expected) {
    for my $meal ( @{ $_->{meals} } ) {
        for my $dish ( @{ $meal->{dishes} } ) {
            $dish->{meal_id} = $meal->{id};
            $dish->{meal}    = $meal;
        }
    }
}
my $project_plan = $plan->project($project);
$_->{date} .= "" for @$project_plan;    # stringify dates for simpler comparison
is_deeply $project_plan => $expected,
  "project()"
  or explain $project_plan;

memory_cycle_ok $project_plan;

done_testing;
