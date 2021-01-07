package Coocook::Schema::ResultSet::Dish;

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
                    from_recipe_id => $recipe->id,
                    servings       => $recipe->servings,    # begin with original servings

                    meal_id => $args{meal},
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
            'meal.date' => { '<=' => $self->format_date_today },
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
            'meal.date' => { '>' => $self->format_date_today },
        },
        {
            join => 'meal',
        }
    );
}

sub update_items_and_delete {
    my $self = shift;

    $self->txn_do(
        sub {
            $self->assert_no_sth;

            while ( my $dish = $self->next ) {
                $dish->update_items_and_delete;
            }
        }
    );
}

1;
