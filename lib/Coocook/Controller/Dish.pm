package Coocook::Controller::Dish;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Dish - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub edit : Path Args(1) {
    my ( $self, $c, $id ) = @_;

    my $dish = $c->model('DB::Dish')->search( undef, { prefetch => 'meal' } )->find($id);

    # candidate meals for preparing this dish: same day or earlier
    my $meals         = $c->model('DB::Meal');
    my $prepare_meals = $meals->search(
        {
            id   => { '!=' => $dish->meal->id },
            date => { '<=' => $meals->format_date( $dish->meal->date ) },
        },
        {
            order_by => 'date',
        }
    );

    $c->stash(
        dish          => $dish,
        ingredients   => [ $dish->ingredients_ordered->all ],
        articles      => [ $c->model('DB::Article')->all ],
        units         => [ $c->model('DB::Unit')->sorted->all ],
        prepare_meals => [ $prepare_meals->all ],
    );
}

sub delete : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;

    my $dish = $c->model('DB::Dish')->find($id);

    $dish->delete;

    $c->response->redirect( $c->uri_for_action( '/meal/edit', $dish->get_column('meal') ) );
}

sub create : Local Args(0) POST {
    my ( $self, $c ) = @_;

    my $dish = $c->model('DB::Dish')->create(
        {
            meal            => scalar $c->req->param('meal'),
            servings        => scalar $c->req->param('servings'),
            name            => scalar $c->req->param('name'),
            description     => scalar $c->req->param('description') // "",
            comment         => scalar $c->req->param('comment') // "",
            preparation     => scalar $c->req->param('preparation') // "",
            prepare_at_meal => scalar $c->req->param('prepare_at_meal') || undef,
        }
    );

    $c->response->redirect( $c->uri_for_action( '/dish/edit', $dish->id ) );
}

sub from_recipe : Local Args(0) POST {
    my ( $self, $c ) = @_;

    my $meal   = $c->model('DB::Meal')->find( scalar $c->req->param('meal') );
    my $recipe = $c->model('DB::Recipe')->find( scalar $c->req->param('recipe') );

    $c->model('DB::Dish')->from_recipe(
        $recipe,
        (
            meal     => $meal->id,
            servings => scalar $c->req->param('servings'),
            comment  => scalar $c->req->param('comment') // "",
        )
    );

    $c->response->redirect( $c->uri_for_action( '/project/edit', $meal->get_column('project') ) );
}

sub recalculate : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;

    my $dish = $c->model('DB::Dish')->find($id);

    $dish->recalculate( scalar $c->req->param('servings') );

    $c->detach( redirect => [$id] );
}

sub add : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;

    $c->model('DB::DishIngredient')->create(
        {
            dish    => $id,
            article => scalar $c->req->param('article'),
            value   => scalar $c->req->param('value'),
            unit    => scalar $c->req->param('unit'),
            comment => scalar $c->req->param('comment'),
            prepare => scalar $c->req->param('prepare') ? '1' : '0',
        }
    );

    $c->detach( redirect => [$id] );
}

sub update : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;

    my $dish = $c->model('DB::Dish')->find($id);

    $c->model('Schema')->schema->txn_do(
        sub {
            $dish->update(
                {
                    name            => scalar $c->req->param('name'),
                    comment         => scalar $c->req->param('comment'),
                    servings        => scalar $c->req->param('servings'),
                    preparation     => scalar $c->req->param('preparation'),
                    description     => scalar $c->req->param('description'),
                    prepare_at_meal => scalar $c->req->param('prepare_at_meal') || undef,

                }
            );

            my $tags = $c->model('DB::Tag')->from_names( scalar $c->req->param('tags') );
            $dish->set_tags( [ $tags->all ] );

            for my $ingredient ( $dish->ingredients->all ) {
                if ( scalar $c->req->param( 'delete' . $ingredient->id ) ) {
                    $ingredient->delete;
                    next;
                }

                $ingredient->update(
                    {
                        prepare => (
                            scalar $c->req->param( 'prepare' . $ingredient->id )
                            ? '1'
                            : '0'
                        ),
                        value   => scalar $c->req->param( 'value' . $ingredient->id ),
                        unit    => scalar $c->req->param( 'unit' . $ingredient->id ),
                        comment => scalar $c->req->param( 'comment' . $ingredient->id ),
                    }
                );
            }
        }
    );

    $c->detach( redirect => [$id] );
}

sub reposition : POST Local Args(1) {
    my ( $self, $c, $id ) = @_;

    my $ingredient = $c->model('DB::DishIngredient')->find($id);

    if ( $c->req->param('up') ) {
        $ingredient->move_previous();
    }
    elsif ( $c->req->param('down') ) {
        $ingredient->move_next();
    }
    else {
        die "No valid movement";
    }

    $c->detach( redirect => [ $ingredient->get_column('dish'), '#ingredients' ] );
}

sub redirect : Private {
    my ( $self, $c, $id, $fragment ) = @_;

    $c->response->redirect(
        $c->uri_for_action( $self->action_for('edit'), $id ) . ( $fragment // '' ) );
}

=encoding utf8

=head1 AUTHOR

Daniel Böhmer,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
