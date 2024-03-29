package Coocook::Controller::Recipe;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use Coocook::Util;
use JSON::MaybeXS;
use Scalar::Util qw(looks_like_number);

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Recipe - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub submenu : Chained('/project/base') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        submenu_items => [
            { text => "All recipes",    action => 'recipe/index' },
            { text => "Add recipe",     action => 'recipe/new_recipe' },
            { text => "Import recipes", action => 'recipe/importable_recipes' },
        ]
    );
}

=head2 index

=cut

sub index : GET HEAD Chained('submenu') PathPart('recipes') Args(0)
  RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my @recipes = $c->project->recipes->sorted->hri->all;

    for my $recipe (@recipes) {
        $recipe->{edit_url}      = $c->project_uri( $self->action_for('edit'),      $recipe->{id} );
        $recipe->{duplicate_url} = $c->project_uri( $self->action_for('duplicate'), $recipe->{id} );
        $recipe->{delete_url}    = $c->project_uri( $self->action_for('delete'),    $recipe->{id} );
    }

    $c->stash( recipes => \@recipes );
}

sub base : Chained('submenu') PathPart('recipe') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( recipe => $c->project->recipes->find($id) || $c->detach('/error/not_found') );
}

sub edit : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my $recipe = $c->stash->{recipe};

    my $ingredients = $c->model('Ingredients')->new(
        project     => $c->project,
        ingredients => $recipe->ingredients,
    );

    my @dishes;
    {
        my $dishes = $recipe->dishes->search(
            undef,
            {
                prefetch => 'meal',
                order_by => 'meal.date',
            }
        );

        while ( my $dish = $dishes->next ) {
            push @dishes,
              {
                name => $dish->name,
                meal => $dish->meal->name,
                date => $dish->meal->date,
                url  => $c->project_uri( '/dish/edit', $dish->id ),
              };
        }
    }

    $c->stash(
        recipe             => $recipe,
        ingredients        => $ingredients->as_arrayref,
        articles           => $ingredients->all_articles,
        units              => $ingredients->all_units,
        dishes             => \@dishes,
        update_url         => $c->project_uri( $self->action_for('update'), $recipe->id ),
        add_ingredient_url => $c->project_uri( $self->action_for('add'),    $recipe->id ),
    );

    $recipe->project->is_public
      and $c->stash( public_url => $c->uri_for_action( '/browse/recipe/show', [ $recipe->id, $recipe->url_name ] ) );

    for my $ingredient ( @{ $c->stash->{ingredients} } ) {
        $ingredient->{reposition_url} = $c->project_uri( '/recipe/reposition', $ingredient->{id} );
    }

    $c->user
      and $c->stash(
        import_url => $c->uri_for_action( '/browse/recipe/import', [ $recipe->id, $recipe->url_name ] ) );

}

sub new_recipe : GET HEAD Chained('submenu') PathPart('recipes/new')
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->stash(
        template   => 'recipe/new.tt',
        create_url => $c->project_uri( $self->action_for('create') ),
    );
}

sub add : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $recipe = $c->stash->{recipe};

    $recipe->create_related(
        ingredients => {
            prepare    => $recipe->format_bool( !!$c->req->params->get('prepare') ),
            article_id => $c->req->params->get('article'),
            value      => $c->req->params->get('value') + 0,
            unit_id    => $c->req->params->get('unit'),
            comment    => $c->req->params->get('comment'),
        }
    );

    $c->detach( redirect => [ $recipe->id, '#ingredients' ] );
}

sub create : POST Chained('submenu') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $name       = $c->req->params->get('name');
    my $input_okay = $self->check_name( $c, { name => $name, current_page => "/recipes" } );
    if ($input_okay) {
        my $recipe = $c->project->create_related(
            recipes => {
                name        => $name,
                description => $c->req->params->get('description') // "",
                preparation => $c->req->params->get('preparation') // "",
                servings    => $c->req->params->get('servings'),
            }
        );
        $c->detach( redirect => [ $recipe->id ] );
    }

}

sub duplicate : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $recipe = $c->stash->{recipe}->duplicate( { name => $c->req->params->get('name') } );

    $c->detach( redirect => [ $recipe->id ] );
}

sub delete : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $recipe = $c->stash->{recipe}->delete;
    $c->detach('redirect');
}

sub update : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $recipe = $c->stash->{recipe};
    my $name   = $c->req->params->get('name');
    my $input_okay =
      $self->check_name( $c, { name => $name, current_page => "/recipe/" . $recipe->id } );
    if ($input_okay) {
        $recipe->txn_do(
            sub {
                $recipe->update(
                    {
                        name        => $name,
                        preparation => $c->req->params->get('preparation'),
                        description => $c->req->params->get('description'),
                        servings    => $c->req->params->get('servings'),
                    }
                );

                # ingredients
                for my $ingredient ( $recipe->ingredients->all ) {
                    if ( $c->req->params->get( 'delete' . $ingredient->id ) ) {
                        $ingredient->delete;
                        next;
                    }

                    $ingredient->update(
                        {
                            prepare => $recipe->format_bool( !!$c->req->params->get( 'prepare' . $ingredient->id ) ),
                            value   => $c->req->params->get( 'value' . $ingredient->id ) + 0,
                            unit_id => $c->req->params->get( 'unit' . $ingredient->id ),
                            comment => $c->req->params->get( 'comment' . $ingredient->id ),
                        }
                    );
                }

                # tags
                my $tags = $c->project->tags_from_names( $c->req->params->get('tags') );
                $recipe->set_tags( [ $tags->all ] );
            }
        );

        $c->detach( 'redirect', [ $recipe->id ] );    # no fragment here, could be text edit

    }

}

sub reposition : POST Chained('/project/base') PathPart('recipe_ingredient/reposition') Args(1)
  RequiresCapability('edit_project') {
    my ( $self, $c, $id ) = @_;

    my $ingredient = $c->project->recipes->search_related('ingredients')->find($id);

    if ( $c->req->params->get('up') ) {
        $ingredient->move_previous();
    }
    elsif ( $c->req->params->get('down') ) {
        $ingredient->move_next();
    }
    else {
        die "No valid movement";
    }

    $c->detach( redirect => [ $ingredient->recipe_id, '#ingredients' ] );
}

sub redirect : Private {
    my ( $self, $c, $recipe, $fragment ) = @_;

    if ($recipe) {
        $c->response->redirect(
            $c->project_uri( $self->action_for('edit'), ref $recipe ? $recipe->id : $recipe )
              . ( $fragment // '' ) );
    }
    else {
        $c->response->redirect( $c->project_uri( $self->action_for('index') ) );
    }
}

sub importable_recipes : GET HEAD Chained('submenu') PathPart('recipes/import') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $recipes = $c->model('DB::Recipe')->public;    # public projects

    $recipes = $recipes->union( $c->user->projects->search_related('recipes') )     # + user's projects
      ->search( { $recipes->me('project_id') => { '!=' => $c->project->id } } );    # - this project

    my @recipes = $recipes->search( undef, { prefetch => { project => 'owner' } } )->all;

    for my $recipe (@recipes) {
        $recipe->{url} = $c->uri_for_action( '/browse/recipe/show', [ $recipe->id, $recipe->url_name ] );

        $recipe->project->{url} ||=
          $c->uri_for_action( '/project/show', [ $recipe->project->id, $recipe->project->url_name ] );

        $recipe->project->owner->{url} ||=
          $c->uri_for_action( '/user/show', [ $recipe->project->owner->name ] );

        $recipe->{import_url} = $c->project_uri( '/recipe/import/preview', $recipe->id );
    }

    $c->stash( recipes => \@recipes );
}

sub check_name : Private {
    my ( $self, $c, $args ) = @_;
    my $name         = $args->{name};
    my $current_page = $args->{current_page};
    my $result       = 1;

    if ( length($name) <= 0 ) {
        $c->messages->error("Cannot create recipe with empty name!");
        $c->response->redirect( $c->uri_for($current_page) );
        $result = 0;
    }

    return $result;
}

sub check_value : Private {
    my ( $self, $c, ) = @_;
}

__PACKAGE__->meta->make_immutable;

1;
