package Coocook::Schema::ResultSet::Dish;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

# retrieves all ingredients from all selected dishes
sub ingredients {
    my $self = shift;

    my $ids = $self->get_column('id')->as_query;

    return $self->result_source->schema->resultset('DishIngredient')
      ->search( { $self->me('dish') => { -in => $ids } } );
}

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
            for my $ingredient ( $recipe->ingredients ) {
                $dish->create_related(
                    ingredients => { map { $_ => $ingredient->$_ } qw<position prepare article unit value comment> } );
            }

            # adjust values of dish ingredients to new servings
            if ( my $servings = $args{servings} ) {
                $dish->recalculate($servings);
            }
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
