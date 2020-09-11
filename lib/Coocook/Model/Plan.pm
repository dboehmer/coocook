package Coocook::Model::Plan;

# ABSTRACT: business logic for plain data structures of project/day plans

use DateTime;
use Moose;
use MooseX::NonMoose;
use Scalar::Util 'weaken';

__PACKAGE__->meta->make_immutable;

sub day {
    my ( $self, $project, $dt ) = @_;

    my %meals;
    my @meals;

    {
        my $meals = $project->meals->search(
            {
                date => $dt->ymd,
            },
            {    # TODO allow manual ordering
                columns  => [ 'id', 'name', 'comment' ],
                order_by => 'id',
            }
        );

        while ( my $meal = $meals->next ) {
            push @meals,
              $meals{ $meal->id } = {
                name            => $meal->name,
                comment         => $meal->comment,
                dishes          => [],
                prepared_dishes => [],
              };
        }
    }

    my %dishes;
    my $schema = $project->result_source->schema;

    {
        my $dishes = $schema->resultset('Dish')->search(
            [    # OR
                meal_id            => { -in => [ keys %meals ] },
                prepare_at_meal_id => { -in => [ keys %meals ] },
            ],
            {
                prefetch => 'prepare_at_meal',
            }
        );

        while ( my $dish = $dishes->next ) {
            my %dish = (
                id          => $dish->id,
                name        => $dish->name,
                comment     => $dish->comment,
                servings    => $dish->servings,
                preparation => $dish->preparation,
                description => $dish->description,
                ingredients => [],
            );

            $dishes{ $dish->id } = \%dish;

            if ( exists $meals{ $dish->meal_id } ) {    # is a dish on this day
                if ( my $meal = $dish->prepare_at_meal ) {
                    $dish{prepare_at_meal_id} = {
                        date => $dish->prepare_at_meal->date,
                        name => $dish->prepare_at_meal->name,
                    };
                }

                push @{ $meals{ $dish->meal_id }{dishes} }, \%dish;
            }

            if ( my $prepare_at_meal = $dish->prepare_at_meal_id ) {
                if ( exists $meals{$prepare_at_meal} ) {    # dish is prepared on this day
                    $dish{meal} = {
                        id   => $dish->meal->id,
                        name => $dish->meal->name,
                        date => $dish->meal->date,
                    };

                    push @{ $meals{ $dish->prepare_at_meal->id }{prepared_dishes} }, \%dish;
                }
            }
        }
    }

    {
        my $ingredients = $schema->resultset('DishIngredient')->search(
            {
                dish_id => { -in => [ keys %dishes ] },
            },
            {
                order_by => 'position',
                prefetch => [ 'article', 'unit' ],
            }
        );

        while ( my $ingredient = $ingredients->next ) {
            push @{ $dishes{ $ingredient->dish_id }{ingredients} },
              {
                prepare => $ingredient->prepare,
                value   => $ingredient->value,
                unit    => {
                    short_name => $ingredient->unit->short_name,
                    long_name  => $ingredient->unit->long_name,
                },
                article => {
                    name    => $ingredient->article->name,
                    comment => $ingredient->article->comment,
                },
                comment => $ingredient->comment,
              };
        }
    }

    return \@meals;
}

sub project {
    my ( $self, $project ) = @_;

    my %days;
    my %meals;

    my $meals = $project->meals;

    while ( my $meal = $meals->next ) {
        my $day = $days{ $meal->date } ||= {
            date  => $meal->date,
            meals => [],
        };

        push @{ $day->{meals} },
          $meals{ $meal->id } = $meal->as_hashref(
            date            => $day->{date},
            deletable       => !!$meal->deletable,
            dishes          => [],
            prepared_dishes => [],
          );
    }

    my $dishes = $meals->search_related('dishes')->hri;

    for my $dish ( $dishes->all ) {
        $dish->{meal} = $meals{ $dish->{meal_id} };

        weaken $dish->{meal};

        push @{ $dish->{meal}{dishes} }, $dish;

        if ( my $prepare_meal_id = $dish->{prepare_at_meal_id} ) {
            push @{ $meals{$prepare_meal_id}{prepared_dishes} }, $dish;
        }
    }

    return [ @days{ sort keys %days } ];
}

1;
