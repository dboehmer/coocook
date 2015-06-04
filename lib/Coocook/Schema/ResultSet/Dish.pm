package Coocook::Schema::ResultSet::Dish;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

sub from_recipe {
    my ( $self, $recipe, %args ) = @_;

    return $self->result_source->schema->txn_do(
        sub {
            my $dish = $self->create(
                {
                    from_recipe => $recipe->id,
                    meal        => $args{meal},
                    comment     => $args{comment},
                    name        => $args{name}        || $recipe->name,
                    servings    => $args{servings}    || $recipe->servings,
                    description => $args{description} || $recipe->description,
                    preparation => $args{preparation} || $recipe->preparation,
                }
            );

            $dish->set_tags( [ $recipe->tags->all ] );

            $dish->recalculate;
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
