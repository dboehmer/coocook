package Coocook::Schema::ResultSet::Dish;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

sub from_recipe {
    my ( $self, %args ) = @_;

    return $self->result_source->schema->txn_do(
        sub {
            my $dish = $self->create(
                {
                    from_recipe => $args{recipe},
                    meal        => $args{meal},
                    name        => $args{name},
                    servings    => $args{servings},
                    comment     => $args{comment},
                }
            );

            $dish->recalculate;
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
