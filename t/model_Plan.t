use Test2::V0;

use Coocook::Model::Plan;
use DateTime;
use Test::Memory::Cycle;
use Test::MockObject;

use lib 't/lib';
use TestDB;

my $db = TestDB->new;

my $project = $db->resultset('Project')->find(1);

ok my $plan = Coocook::Model::Plan->new( schema => $db );

my $day = $plan->day( $project, DateTime->new( year => 2000, month => 1, day => 1 ) );
is $day => [
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
  "day(2000-01-01)";

memory_cycle_ok $day;

my $day2 = $plan->day( $project, DateTime->new( year => 2000, month => 1, day => 2 ) );
is $day2 => array {
    item hash {
        field name   => 'lunch';
        field dishes => array {
            item hash { field name => 'pizza'; etc() };
        };
        field prepared_dishes => array {
            item hash {
                field name => 'bread';
                field meal => hash {
                    field id   => 3;
                    field name => 'dinner';
                    etc();
                };
                etc();
            };
        };
        etc();
    },
},
  "day(2000-01-02) with prepared dish";

memory_cycle_ok $day2;

is my $project_plan = $plan->project($project) => array {
    my $bread;

    item hash {
        field date  => string '2000-01-01T00:00:00';
        field meals => array {
            item hash {
                field id         => 1;
                field project_id => 1;
                field date       => string '2000-01-01T00:00:00';
                field name       => 'breakfast';
                field comment    => 'Best meal of the day!';
                field deletable  => F();
                field dishes     => array {
                    item hash {
                        field id                 => 1;
                        field meal_id            => 1;
                        field meal               => hash { field id => 1; etc() };
                        field prepare_at_meal_id => U();
                        field from_recipe_id     => U();
                        field name               => 'pancakes';
                        field preparation        => '';
                        field description        => 'Make them really sweet!';
                        field comment            => '';
                        field servings           => 4;
                    };
                };
                field prepared_dishes => [];
            };
        };
    };
    item hash {
        field date  => string '2000-01-02T00:00:00';
        field meals => array {
            item hash {
                field id         => 2;
                field project_id => 1;
                field date       => string '2000-01-02T00:00:00';
                field name       => 'lunch';
                field comment    => '';
                field deletable  => F();
                field dishes     => array {
                    item hash {
                        field id                 => 2;
                        field meal_id            => 2;
                        field meal               => hash { field id => 2; etc() };
                        field prepare_at_meal_id => U();
                        field from_recipe_id     => 1;
                        field name               => 'pizza';
                        field preparation        => '';
                        field description        => '';
                        field comment            => '';
                        field servings           => 2;
                    };
                };
                field prepared_dishes => array {
                    item $bread = hash {
                        field id                 => 3;
                        field meal_id            => 3;
                        field meal               => hash { field id => 3; etc() };
                        field prepare_at_meal_id => 2;
                        field from_recipe_id     => U();
                        field name               => 'bread';
                        field preparation        => 'Bake bread!';
                        field description        => '';
                        field comment            => '';
                        field servings           => 4;
                    };
                };
            };
        };
    };
    item hash {
        field date  => string '2000-01-03T00:00:00';
        field meals => array {
            item hash {
                field id              => 3;
                field project_id      => 1;
                field date            => string '2000-01-03T00:00:00';
                field name            => 'dinner';
                field deletable       => F();
                field dishes          => array { item $bread };
                field prepared_dishes => [];
                field comment         => '';
            };
        };
    };
},
  "project()";

memory_cycle_ok $project_plan;

subtest deletable => sub {
    ok !$plan->project($project)->[1]{meals}[0]{deletable};
    $db->resultset('Meal')->find(2)->delete_dishes();
    ok !$plan->project($project)->[1]{meals}[0]{deletable};
    $db->resultset('Dish')->find(3)->update( { prepare_at_meal_id => undef } );
    ok $plan->project($project)->[1]{meals}[0]{deletable};
};

done_testing;
