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
            [
                meal            => { -in => [ keys %meals ] },
                prepare_at_meal => { -in => [ keys %meals ] },
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

            if ( exists $meals{ $dish->get_column('meal') } ) {    # is a dish on this day
                if ( my $meal = $dish->prepare_at_meal ) {
                    $dish{prepare_at_meal} = {
                        date => $dish->prepare_at_meal->date,
                        name => $dish->prepare_at_meal->name,
                    };
                }

                push @{ $meals{ $dish->get_column('meal') }{dishes} }, \%dish;
            }

            if ( my $prepare_at_meal = $dish->get_column('prepare_at_meal') ) {
                if ( exists $meals{$prepare_at_meal} ) {           # dish is prepared on this day
                    $dish{meal} = {
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
                dish => { -in => [ keys %dishes ] },
            },
            {
                order_by => 'position',
                prefetch => [ 'article', 'unit' ],
            }
        );

        while ( my $ingredient = $ingredients->next ) {
            push @{ $dishes{ $ingredient->get_column('dish') }{ingredients} },
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

    my $meals = $project->meals->hri;
    my @meals = $meals->all;
    my %meals = map { $_->{id} => $_ } @meals;

    for my $meal (@meals) {
        my $day = $days{ $meal->{date} } ||= {
            date  => $meals->parse_date( $meal->{date} ),
            meals => [],
        };

        push @{ $day->{meals} }, $meal;

        $meal->{date}            = $day->{date};
        $meal->{dishes}          = [];
        $meal->{prepared_dishes} = [];
    }

    my $dishes = $meals->search_related('dishes')->hri;

    for my $dish ( $dishes->all ) {
        $_ = $meals{$_} for $dish->{meal};

        weaken $dish->{meal};

        push @{ $dish->{meal}{dishes} }, $dish;

        if ( my $prepare_meal_id = $dish->{prepare_at_meal} ) {
            push @{ $meals{$prepare_meal_id}{prepared_dishes} }, $dish;
        }
    }

    return [ @days{ sort keys %days } ];
}

1;
