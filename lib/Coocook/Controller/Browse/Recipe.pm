package Coocook::Controller::Browse::Recipe;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use Coocook::Util;
use Scalar::Util qw(looks_like_number);

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Browse::Recipe - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub index : GET HEAD Chained('/base') PathPart('recipes') Args(0) Public {
    my ( $self, $c ) = @_;

    my $recipes = $c->model('DB::Recipe');

    if ( $c->req->params->get('show_all') ) {
        $c->require_capability('view_all_recipes');

        $c->stash( show_less_url => $c->uri_for( $c->action ) );
    }
    else {
        $c->has_capability('view_all_recipes')
          and $c->stash( show_all_url => $c->uri_for( $c->action, { show_all => 1 } ) );

        $recipes = $recipes->public;

        if ( my $user = $c->user ) {
            $recipes = $recipes->union( $user->projects->search_related('recipes') );
        }
    }

    my @recipes = $recipes->search( undef, { columns => [qw< id project name >] } )->hri->all;

    {
        my $projects =
          $recipes->search_related( 'project', undef,
            { columns => [qw< id owner name url_name is_public >] } );

        my %projects = map { $_->{id} => $_ } $projects->hri->all;

        my %users = map { $_->{id} => $_ } $projects->search_related('owner')->hri->all;

        for my $user ( values %users ) {
            $user->{url} = $c->uri_for_action( '/user/show', [ $user->{name} ] );
        }

        for my $project ( values %projects ) {
            $project->{owner} = $users{ $project->{owner} }
              or die "User for owner ID not found";

            $project->{url} = $c->uri_for_action( '/project/show', [ $project->{id}, $project->{url_name} ] );
        }

        for my $recipe (@recipes) {
            my $project = $projects{ $recipe->{project} }
              or die "Project for project ID not found";

            $recipe->{project}  = $project;
            $recipe->{url_name} = Coocook::Util::url_name( $recipe->{name} );

            $c->user
              and $recipe->{import_url} =
              $c->uri_for( $self->action_for('import'), [ $recipe->{id}, $recipe->{url_name} ] );

            $recipe->{url} =
              $c->uri_for( $self->action_for('show'), [ $recipe->{id}, $recipe->{url_name} ] );
        }
    }

    $c->stash( recipes => \@recipes );
}

sub base : Chained('/base') PathPart('recipe') CaptureArgs(2) {
    my ( $self, $c, $id, $url_name ) = @_;

    my $recipe = $c->model('DB::Recipe')->search( undef, { prefetch => 'project' } )->find($id)
      or $c->detach('/error/not_found');

    $c->redirect_canonical_case( 1 => $recipe->url_name );

    $c->stash(
        recipe         => $recipe,
        source_project => $recipe->project,
    );
}

sub import : GET HEAD Chained('base') PathPart('import') Args(0)
  RequiresCapability('export_from_project') {
    my ( $self, $c ) = @_;

    my $recipe = $c->stash->{recipe};

    $recipe->{url} =
      $c->uri_for( $self->action_for('show'), [ $recipe->id, $recipe->url_name ] );

    $recipe->project->{url} =
      $c->uri_for_action( '/project/show', [ $recipe->project->id, $recipe->project->url_name ] );

    # TODO should site admins see a list of all projects??
    my $projects = $c->user->projects_users->search(
        {
            role => { -in => [qw< editor admin owner >] },
        }
    )->search_related(
        project => {
            archived => undef,                                         # projects are not yet archived
            id       => { '!=' => $recipe->get_column('project') },    # not this recipe's source project
        }
    );

    my @projects = $projects->hri->all;

    for my $project (@projects) {
        $project->{import_url} =
          $c->uri_for_action( '/recipe/import/preview',
            [ $project->{id}, $project->{url_name}, $recipe->id ] );

        $project->{url} = $c->uri_for_action( '/project/show', [ $project->{id}, $project->{url_name} ] );
    }

    $c->stash( projects => \@projects );
}

sub show : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('view_recipe') {
    my ( $self, $c ) = @_;

    my $recipe  = $c->stash->{recipe};
    my $project = $recipe->project;

    my $factor = 1;
    my $servings;

    if ( $servings = $c->req->params->get('servings') ) {
        $factor = $servings / $recipe->servings;
    }

    $servings ||= $recipe->servings;

    my %ingredients;

    for my $block (qw< prepared not_prepared >) {
        my $ingredients = $recipe->ingredients->$block();

        $ingredients{$block} = $c->model('Ingredients')->new(
            factor      => $factor,
            ingredients => $ingredients,
            project     => $project,
        )->as_arrayref;
    }

    $c->user
      and $c->stash(
        import_url => $c->uri_for( $self->action_for('import'), [ $recipe->id, $recipe->url_name ] ) );

    $c->stash(
        recipe                   => $recipe,
        servings                 => $servings,
        prepared_ingredients     => $ingredients{prepared},
        not_prepared_ingredients => $ingredients{not_prepared},
        project_url              => $c->uri_for_action_if_permitted(
            '/recipe/edit',
            { project => $project },
            [ $project->id, $project->url_name, $recipe->id ]
        ),
    );
}

__PACKAGE__->meta->make_immutable;

1;
