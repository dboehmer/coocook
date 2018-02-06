package Coocook::Controller::Project;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Project - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 base

Chain action that captures the project ID and stores the
C<Result::Project> object in the stash.

=cut

sub base : Chained('/base') PathPart('project') CaptureArgs(1) {
    my ( $self, $c, $url_name ) = @_;

    my $project = $c->model('DB::Project')->find_by_url_name($url_name)
      or $c->detach('/error/not_found');

    if ( $c->req->method eq 'GET' and $url_name ne $project->url_name ) {

        # TODO redirect to same URL with $url_name in exact case
        # e.g. /project/fOO => /project/Foo (for url_name 'Foo' in database)
    }

    $c->stash( project => $project );
}

=head2 index

=cut

sub edit : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    $c->has_capability('view_project')
      or $c->detach('/error/forbidden');

    my $default_date = DateTime->today;

    my $days = $c->model('Plan')->project( $c->project );

    # calculate dishes per day for table's row-span
    for my $day (@$days) {
        $day->{dishes} = 0;

        for my $meal ( @{ $day->{meals} } ) {
            my $dishes = @{ $meal->{dishes} };
            $day->{dishes} += $dishes;
            $meal->{deletable} = not $dishes;
        }
    }

    $c->stash(
        default_date         => $default_date,
        recipes              => [ $c->project->recipes->sorted->all ],
        days                 => $days,
        dish_create_url      => $c->project_uri('/dish/create'),
        dish_from_recipe_url => $c->project_uri('/dish/from_recipe'),
        meal_create_url      => $c->project_uri('/meal/create'),

        permissions_url => $c->has_capability('view_project_permissions')
        ? $c->project_uri('/permission/index')
        : undef,

        settings_url => $c->has_capability('view_project_settings')
        ? $c->project_uri('/project/settings')
        : undef,
    );
}

sub settings : GET HEAD Chained('base') PathPart('settings') Args(0)
  RequiresCapability('view_project_settings') {
    my ( $self, $c ) = @_;

    $c->stash(
        rename_url            => $c->project_uri('/project/rename'),
        visibility_url        => $c->project_uri('/project/visibility'),
        delete_url            => $c->project_uri('/project/delete'),
        deletion_confirmation => $c->config->{project_deletion_confirmation},
    );

    $c->escape_title( "Project settings" => $c->project->name );
}

sub importable_projects : Private {
    my ( $self, $c ) = @_;

    return [ grep { $c->has_capability( import_from_project => { project => $_ } ) }
          $c->project->other_projects->all ];
}

sub get_import : GET HEAD Chained('base') PathPart('import') Args(0)
  RequiresCapability('import_into_project') {    # import() already used by 'use'
    my ( $self, $c ) = @_;

    my $importer = $c->model('Importer');

    $c->stash(
        projects        => $c->forward('importable_projects'),
        properties      => $importer->properties,
        properties_json => $importer->properties_json,
        import_url      => $c->project_uri('/project/post_import'),
        template        => 'project/import.tt',
        title           => "Import",
    );
}

sub post_import : POST Chained('base') PathPart('import') Args(0)
  RequiresCapability('import_into_project') {    # import() already used by 'use'
    my ( $self, $c ) = @_;

    my $importer = $c->model('Importer');
    my $source   = $c->model('DB::Project')->find( $c->req->params->get('source_project') );
    my $target   = $c->project;

    $c->has_capability( import_from_project => { project => $source } )
      or $c->detach('/error/forbidden');

    # extract properties selected in form
    my @properties =
      grep { $c->req->params->get("property_$_") } map { $_->{key} } @{ $importer->properties };

    $importer->import_data( $source => $target, \@properties );

    $c->detach( redirect => [$target] );
}

sub create : POST Chained('/base') PathPart('project/create') Args(0)
  RequiresCapability('create_project') {
    my ( $self, $c ) = @_;

    my $name = $c->req->params->get('name');

    length $name > 0
      or
      $c->redirect_detach( $c->uri_for( '/', { error => "Cannot create project with empty name!" } ) );

    my $is_public = $c->req->params->get('is_public') ? 1 : 0;

    ( $is_public or $c->has_capability('create_private_project') )
      or $c->redirect_detach(
        $c->uri_for( '/', { error => "You're not allowed to create private projects" } ) );

    $c->txn_do(
        sub {
            my $project = $c->stash->{project} = $c->model('DB::Project')->create(
                {
                    name      => $c->req->params->get('name'),
                    owner     => $c->user->id,
                    is_public => $is_public,
                }
            );

            $project->create_related(
                projects_users => {
                    user => $c->user->id,
                    role => 'owner',
                }
            );
        }
    );

    my $importable_projects = $c->forward('importable_projects');

    $c->response->redirect(
        $c->project_uri( $self->action_for( @$importable_projects > 0 ? 'get_import' : 'edit' ) ) );
}

sub rename : POST Chained('base') Args(0) RequiresCapability('rename_project') {
    my ( $self, $c ) = @_;

    my $project = $c->stash->{project};

    $project->update( { name => $c->req->params->get('name') } );

    $c->response->redirect( $c->project_uri('/project/settings') );
}

sub visibility : POST Chained('base') Args(0) RequiresCapability('edit_project_visibility') {
    my ( $self, $c ) = @_;

    my $project = $c->stash->{project};

    $project->update( { is_public => $c->req->params->get('public') ? 1 : 0 } );

    $c->response->redirect( $c->project_uri('/project/settings') );
}

sub delete : POST Chained('base') Args(0) RequiresCapability('delete_project') {
    my ( $self, $c ) = @_;

    if ( $c->req->params->get('confirmation') eq $c->config->{project_deletion_confirmation} ) {
        $c->project->delete;
        $c->response->redirect( $c->uri_for_action('/index') );
    }
    else {
        $c->response->redirect( $c->project_uri('/project/settings') );
    }
}

sub redirect : Private {
    my ( $self, $c, $project ) = @_;

    $c->response->redirect( $c->uri_for_action( $self->action_for('edit'), [ $project->url_name ] ) );
}

__PACKAGE__->meta->make_immutable;

1;
