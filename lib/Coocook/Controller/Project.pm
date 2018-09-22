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

    $c->stash(
        project_urls => {
            project          => $c->project_uri('/project/show'),
            recipes          => $c->project_uri('/recipe/index'),
            articles         => $c->project_uri('/article/index'),
            tags             => $c->project_uri('/tag/index'),
            unassigned_items => $c->project_uri('/items/unassigned'),
            purchase_lists   => $c->project_uri('/purchase_list/index'),
            print            => $c->project_uri('/print/index'),
            shop_sections    => $c->project_uri('/shop_section/index'),
            quantities       => $c->project_uri('/quantity/index'),
            units            => $c->project_uri('/unit/index'),
            import           => $c->project_uri('/project/get_import'),
        },
    );
}

sub submenu : Chained('base') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    my @subitems = (
        { text => "Show project", action => 'project/show',     capability => 'view_project' },
        { text => "Edit project", action => 'project/edit',     capability => 'edit_project' },
        { text => "Permissions",  action => 'permission/index', capability => 'view_project_permissions' },
        { text => "Project settings", action => 'project/settings', capability => 'view_project_settings' },
    );

    for my $item (@subitems) {
        if ( not $c->has_capability( $item->{capability} ) ) {
            $item->{forbidden} = 1;
            next;
        }

        if ( $c->action ne $item->{action} ) {
            $item->{url} = $c->project_uri( $item->{action} );
        }
    }

    # remove subitems that have the 'forbidden' flag
    @subitems = grep { not $_->{forbidden} } @subitems;

    $c->stash( submenu_items => \@subitems );
}

sub show : GET HEAD Chained('submenu') PathPart('') Args(0) RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my $days = $c->model('Plan')->project( $c->project );

    for my $day (@$days) {
        for my $meal ( @{ $day->{meals} } ) {
            for my $dish ( @{ $meal->{dishes} } ) {
                $dish->{url} = $c->project_uri( '/dish/edit', $dish->{id} );
            }
        }
    }

    $c->stash(
        days      => $days,
        inventory => $c->project->inventory,
    );
}

sub edit : GET HEAD Chained('submenu') PathPart('edit') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $default_date = DateTime->today;

    my $days = $c->model('Plan')->project( $c->project );

    # calculate dishes per day for table's row-span
    for my $day (@$days) {
        $day->{dishes} = 0;

        for my $meal ( @{ $day->{meals} } ) {
            my $dishes = $meal->{dishes};

            for my $dish (@$dishes) {
                $dish->{url} = $c->project_uri( '/dish/edit', $dish->{id} );
            }

            $day->{dishes} += @$dishes;

            $meal->{update_url} = $c->project_uri( '/meal/update', $meal->{id} );

            $meal->{delete_url} = $c->project_uri( '/meal/delete', $meal->{id} )
              unless @$dishes > 0;
        }
    }

    $c->stash(
        default_date         => $default_date,
        recipes              => [ $c->project->recipes->sorted->all ],
        days                 => $days,
        dish_create_url      => $c->project_uri('/dish/create'),
        dish_from_recipe_url => $c->project_uri('/dish/from_recipe'),
        meal_create_url      => $c->project_uri('/meal/create'),
    );
}

sub settings : GET HEAD Chained('submenu') PathPart('settings') Args(0)
  RequiresCapability('view_project_settings') {
    my ( $self, $c ) = @_;

    $c->stash(
        update_url            => $c->project_uri('/project/update'),
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

    my $project = $c->stash->{project} = $c->model('DB::Project')->create(
        {
            name           => $c->req->params->get('name'),
            description    => '',
            owner          => $c->user->id,
            is_public      => $is_public,
            projects_users => [                               # relationship automatically triggers transaction
                {
                    user => $c->user->id,
                    role => 'owner',
                }
            ],
        }
    );

    my $importable_projects = $c->forward('importable_projects');

    $c->response->redirect(
        $c->project_uri( $self->action_for( @$importable_projects > 0 ? 'get_import' : 'show' ) ) );
}

sub update : POST Chained('base') Args(0) RequiresCapability('update_project') {
    my ( $self, $c ) = @_;

    my $project = $c->stash->{project};

    $project->update(
        { description => $c->req->params->get('description') // $c->detach('/error/bad_request') } );

    $c->response->redirect( $c->project_uri('/project/settings') );
}

sub rename : POST Chained('base') Args(0) RequiresCapability('rename_project') {
    my ( $self, $c ) = @_;

    my $project = $c->stash->{project};

    $project->update( { name => $c->req->params->get('name') // $c->detach('/error/bad_request') } );

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

    $c->response->redirect( $c->uri_for_action( $self->action_for('show'), [ $project->url_name ] ) );
}

__PACKAGE__->meta->make_immutable;

1;
