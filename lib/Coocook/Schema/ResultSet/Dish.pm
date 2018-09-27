package Coocook::Schema::ResultSet::Dish;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->meta->make_immutable;

sub from_recipe {
    my ( $self, $recipe, %args ) = @_;

    return $self->txn_do(
        sub {
            my $dish = $self->create(
                {
                    from_recipe => $recipe->id,
                    servings    => $recipe->servings,    # begin with original servings

                    meal    => $args{meal},
                    comment => $args{comment},

                    name        => $args{name}        || $recipe->name,
                    description => $args{description} || $recipe->description,
                    preparation => $args{preparation} || $recipe->preparation,
                }
            );

            $dish->set_tags( [ $recipe->tags->all ] );

            # copy ingredients
            for my $ingredient ( $recipe->ingredients->all ) {
                $dish->create_related(
                    ingredients => { map { $_ => $ingredient->$_ } qw<position prepare article unit value comment> } );
            }

            # adjust values of dish ingredients to new servings
            if ( my $servings = $args{servings} ) {
                $dish->recalculate($servings);
            }

            return $dish;
        }
    );
}

sub sum_servings { shift->get_column('servings')->sum // 0 }

sub in_past_or_today {
    my $self = shift;

    return $self->search(
        {
            'meal.date' => { '<=' => $self->format_date( DateTime->today ) },
        },
        {
            join => 'meal',
        }
    );
}

sub in_future {
    my $self = shift;

    return $self->search(
        {
            'meal.date' => { '>' => $self->format_date( DateTime->today ) },
        },
        {
            join => 'meal',
        }
    );
}

1;
