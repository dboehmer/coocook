package Coocook::Schema::ResultSet::Dish;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->meta->make_immutable;

sub from_recipe {
    my ( $self, $recipe, %args ) = @_;

    return $self->result_source->schema->txn_do(
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

=head2 count_served

Returns the approximate number of dishes served until today.
That is the sum of the number of servings all dishes of all meals
scheduled for the past or today.

=cut

sub count_served {
    my $self = shift;

    return $self->search(
        {
            'meal.date' => { '<=' => $self->format_date( DateTime->today ) },
        },
        {
            join => 'meal',
        }
    )->get_column('servings')->sum;
}

1;
