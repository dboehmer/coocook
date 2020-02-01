package Coocook::Controller::Dish;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Dish - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base : Chained('/project/submenu') PathPart('dish') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash(
        dish => $c->project->dishes->search(
            undef,
            {
                prefetch => [ 'meal', 'recipe' ],
            }
        )->find($id)
          || $c->detach('/error/not_found')
    );
}

sub edit : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my $dish = $c->stash->{dish};

    my $ingredients = $c->model('Ingredients')->new(
        project     => $c->project,
        ingredients => $dish->ingredients,
    );

    # candidate meals for preparing this dish: same day or earlier
    my $meals = $c->project->meals;
    my $prepare_meals =
      $meals->search( { date => { '<=' => $meals->format_date( $dish->meal->date ) } },
        { order_by => 'date' } );

    $c->stash(
        dish => {
            name        => $dish->name,
            comment     => $dish->comment,
            servings    => $dish->servings,
            preparation => $dish->preparation,
            description => $dish->description,
            tags_joined => $dish->tags_rs->joined,
            meal        => $dish->meal,

            recipe => $dish->recipe
            ? {
                name => $dish->recipe->name,
                url  => $c->project_uri( '/recipe/edit', $dish->recipe->id ),
              }
            : undef,

            # undef or hashref with only 'id' property for comparisons
            prepare_at_meal => map( { $_ ? { id => $_ } : undef } $dish->get_column('prepare_at_meal') ),

            recalculate_url => $c->project_uri( $self->action_for('recalculate'), $dish->id ),
            update_url      => $c->project_uri( $self->action_for('update'),      $dish->id ),
        },
        ingredients        => $ingredients->as_arrayref,
        articles           => $ingredients->all_articles,
        units              => $ingredients->all_units,
        prepare_meals      => [ $prepare_meals->all ],
        add_ingredient_url => $c->project_uri( '/dish/add', $dish->id ),
        delete_url         => $c->project_uri( '/dish/delete', $dish->id ),
    );

    for my $ingredient ( @{ $c->stash->{ingredients} } ) {
        $ingredient->{reposition_url} = $c->project_uri( '/dish/reposition', $ingredient->{id} );
    }
}

sub delete : POST Chained('base') PathPart('delete') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->stash->{dish}->update_items_and_delete;

    $c->response->redirect( $c->project_uri('/project/edit') );
}

sub create : POST Chained('/project/base') PathPart('dishes/create') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $meal = $c->project->meals->find( $c->req->params->get('meal') );

    my $dish = $meal->create_related(
        dishes => {
            servings        => $c->req->params->get('servings'),
            name            => $c->req->params->get('name'),
            description     => $c->req->params->get('description') // "",
            comment         => $c->req->params->get('comment') // "",
            preparation     => $c->req->params->get('preparation') // "",
            prepare_at_meal => $c->req->params->get('prepare_at_meal') || undef,
        }
    );

    $c->response->redirect( $c->project_uri( '/dish/edit', $dish->id ) );
}

sub from_recipe : POST Chained('/project/base') PathPart('dishes/from_recipe') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $meal   = $c->project->meals->find( $c->req->params->get('meal') );
    my $recipe = $c->project->recipes->find( $c->req->params->get('recipe') );

    my $dish = $c->model('DB::Dish')->from_recipe(
        $recipe,
        (
            meal     => $meal->id,
            servings => $c->req->params->get('servings'),
            comment  => $c->req->params->get('comment') // "",
        )
    );

    $c->response->redirect( $c->project_uri( '/dish/edit', $dish->id ) );
}

sub recalculate : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $dish = $c->stash->{dish};

    $dish->recalculate( $c->req->params->get('servings') );

    $c->detach( redirect => [ $dish->id, '#ingredients' ] );
}

sub add : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $dish = $c->stash->{dish};

    $dish->create_related(
        ingredients => {
            article => $c->req->params->get('article'),
            value   => $c->req->params->get('value') + 0,
            unit    => $c->req->params->get('unit'),
            comment => $c->req->params->get('comment'),
            prepare => !!$c->req->params->get('prepare'),
        }
    );

    $c->detach( redirect => [ $dish->id, '#ingredients' ] );
}

sub update : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $dish = $c->stash->{dish};

    $dish->txn_do(
        sub {
            $dish->update(
                {
                    name            => $c->req->params->get('name'),
                    comment         => $c->req->params->get('comment'),
                    servings        => $c->req->params->get('servings'),
                    preparation     => $c->req->params->get('preparation'),
                    description     => $c->req->params->get('description'),
                    prepare_at_meal => $c->req->params->get('prepare_at_meal') || undef,

                }
            );

            my $tags = $c->project->tags->from_names( $c->req->params->get('tags') );
            $dish->set_tags( [ $tags->all ] );

            for my $ingredient ( $dish->ingredients->all ) {
                my $item = $ingredient->item;

                if ( $c->req->params->get( 'delete' . $ingredient->id ) ) {
                    $ingredient->remove_from_purchase_list;
                    $ingredient->delete;
                }
                else {
                    $ingredient->update(
                        {
                            prepare => !!$c->req->params->get( 'prepare' . $ingredient->id ),
                            value   => $c->req->params->get( 'value' . $ingredient->id ) + 0,
                            unit    => $c->req->params->get( 'unit' . $ingredient->id ),
                            comment => $c->req->params->get( 'comment' . $ingredient->id ),
                        }
                    );
                }

                $item and $item->in_storage or next;

                $item->update_from_ingredients();

            }
        }
    );

    $c->detach( redirect => [ $dish->id, '#ingredients' ] );
}

sub reposition : POST Chained('/project/base') PathPart('dish_ingredient/reposition') Args(1)
  RequiresCapability('edit_project') {
    my ( $self, $c, $id ) = @_;

    my $ingredient = $c->project->dishes->search_related('ingredients')->find($id);

    if ( $c->req->params->get('up') ) {
        $ingredient->move_previous();
    }
    elsif ( $c->req->params->get('down') ) {
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

__PACKAGE__->meta->make_immutable;

1;
