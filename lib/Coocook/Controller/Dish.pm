package Coocook::Controller::Dish;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

Coocook::Controller::Dish - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base : Chained('/project/base') PathPart('dish') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    # TODO error handling
    $c->stash( dish => $c->project->dishes->search( undef, { prefetch => 'meal' } )->find($id) );
}

sub edit : GET Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $dish = $c->stash->{dish};

    # candidate meals for preparing this dish: same day or earlier
    my $meals         = $c->project->meals;
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
        articles      => [ $c->project->articles->all ],
        units         => [ $c->project->units->sorted->all ],
        prepare_meals => [ $prepare_meals->all ],
    );

    $c->escape_title( Dish => $dish->name );
}

sub delete : Local Args(1) POST {    # TODO fix
    my ( $self, $c, $id ) = @_;

    my $dish = $c->project->dishes->find($id);

    $dish->delete;

    $c->response->redirect( $c->project_uri( '/meal/edit', $dish->get_column('meal') ) );
}

sub create : POST Chained('/project/base') PathPart('dishes/create') Args(0) {
    my ( $self, $c ) = @_;

    my $meal = $c->project->meals->find( scalar scalar $c->req->param('meal') );

    my $dish = $meal->create_related(
        dishes => {
            servings        => scalar $c->req->param('servings'),
            name            => scalar $c->req->param('name'),
            description     => scalar $c->req->param('description') // "",
            comment         => scalar $c->req->param('comment') // "",
            preparation     => scalar $c->req->param('preparation') // "",
            prepare_at_meal => scalar $c->req->param('prepare_at_meal') || undef,
        }
    );

    $c->response->redirect( $c->project_uri( '/dish/edit', $dish->id ) );
}

sub from_recipe : POST Chained('/project/base') PathPart('dishes/from_recipe') Args(0) {
    my ( $self, $c ) = @_;

    my $meal   = $c->project->meals->find( scalar $c->req->param('meal') );
    my $recipe = $c->project->recipes->find( scalar $c->req->param('recipe') );

    my $dish = $c->model('DB::Dish')->from_recipe(
        $recipe,
        (
            meal     => $meal->id,
            servings => scalar $c->req->param('servings'),
            comment  => scalar $c->req->param('comment') // "",
        )
    );

    $c->response->redirect( $c->project_uri( '/dish/edit', $dish->id ) );
}

sub recalculate : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $dish = $c->stash->{dish};

    $dish->recalculate( scalar $c->req->param('servings') );

    $c->detach( redirect => [ $dish->id, '#ingredients' ] );
}

sub add : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $dish = $c->stash->{dish};

    $dish->create_related(
        ingredients => {
            article => scalar $c->req->param('article'),
            value   => scalar $c->req->param('value'),
            unit    => scalar $c->req->param('unit'),
            comment => scalar $c->req->param('comment'),
            prepare => scalar $c->req->param('prepare') ? '1' : '0',
        }
    );

    $c->detach( redirect => [ $dish->id, '#ingredients' ] );
}

sub update : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $dish = $c->stash->{dish};

    $c->model('DB')->schema->txn_do(
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

            my $tags = $c->project->tags->from_names( scalar $c->req->param('tags') );
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

    $c->detach( redirect => [ $dish->id, '#ingredients' ] );
}

sub reposition : POST Chained('/project/base') PathPart('dish_ingredient/reposition') Args(1) {
    my ( $self, $c, $id ) = @_;

    my $ingredient = $c->project->dishes->ingredients->find($id);

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

    $c->response->redirect( $c->project_uri( $self->action_for('edit'), $id ) . ( $fragment // '' ) );
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
