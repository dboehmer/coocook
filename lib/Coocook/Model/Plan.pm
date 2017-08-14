package Coocook::Model::Plan;

use DateTime;
use Moose;
use MooseX::NonMoose;

extends 'Catalyst::Model';

has schema => (
    is  => 'rw',
    isa => 'Coocook::Schema',
);

__PACKAGE__->meta->make_immutable;

sub COMPONENT {
    my ( $class, $app, $args ) = @_;

    my $schema = $app->model('Schema')->schema;

    my $self = $class->new( $app, $args );
    $self->schema($schema);
    return $self;
}

sub day {
    my ( $self, $dt ) = @_;

    my %meals;
    my @meals;

    {
        my $meals = $self->schema->resultset('Meal')->search(
            {
                date => $dt->ymd,
            },
            {
                columns  => [ 'id', 'name' ],
                order_by => 'id',
            }
        );

        while ( my $meal = $meals->next ) {
            push @meals,
              $meals{ $meal->id } = {
                name            => $meal->name,
                dishes          => [],
                prepared_dishes => [],
              };
        }
    }

    my %dishes;

    {
        my $dishes = $self->schema->resultset('Dish')->search(
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
        my $ingredients = $self->schema->resultset('DishIngredient')->search(
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

1;
