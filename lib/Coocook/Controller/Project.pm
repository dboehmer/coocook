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

    $c->redirect_canonical_case( 0 => $project->url_name );

    $project->is_public
      or $c->stash->{robots}->index(0);

    $c->stash( project => $project );

    $c->stash(
        project_urls => {
            project          => $c->project_uri('/project/show'),
            edit             => $c->project_uri('/project/edit'),
            recipes          => $c->project_uri('/recipe/index'),
            articles         => $c->project_uri('/article/index'),
            tags             => $c->project_uri('/tag/index'),
            unassigned_items => $c->project_uri('/items/unassigned'),
            purchase_lists   => $c->project_uri('/purchase_list/index'),
            print            => $c->project_uri('/print/index'),
            shop_sections    => $c->project_uri('/shop_section/index'),
            units            => $c->project_uri('/unit/index'),
            quantities       => $c->project_uri('/quantity/index'),
            import           => $c->project_uri('/project/get_import'),
            archive          => $c->project_uri('/project/archive'),
            unarchive        => $c->project_uri('/project/unarchive'),
        },
    );
}

sub submenu : Chained('base') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        submenu_items => [
            { text => "Show project",   action => 'project/show' },
            { text => "Meals & Dishes", action => 'project/edit' },
            { text => "Permissions",    action => 'permission/index' },
            { text => "Settings",       action => 'project/settings' },
        ],
    );
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
        can_edit      => !!$c->has_capability('edit_project'),
        can_unarchive => !!$c->has_capability('unarchive_project'),
        days          => $days,
        inventory     => $c->project->inventory,
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
}

sub exportable_projects : Private {
    my ( $self, $c ) = @_;

    return [ grep { $c->has_capability( export_from_project => { source_project => $_ } ) }
          $c->project->other_projects->all ];
}

sub get_import : GET HEAD Chained('base') PathPart('import') Args(0)
  RequiresCapability('import_into_project') {    # import() already used by 'use'
    my ( $self, $c ) = @_;

    my $importer = $c->model('ProjectImporter');

    $c->stash(
        projects        => $c->forward('exportable_projects'),
        properties      => $importer->properties,
        properties_json => $importer->properties_json,
        import_url      => $c->project_uri('/project/post_import'),
        template        => 'project/import.tt',
    );
}

sub post_import : POST Chained('base') PathPart('import') Args(0)
  RequiresCapability('import_into_project') {    # import() already used by 'use'
    my ( $self, $c ) = @_;

    my $importer = $c->model('ProjectImporter');

    my $source = $c->model('DB::Project')->find( $c->req->params->get('source_project') )
      or $c->detach('/error/bad_request');

    my $target = $c->project;

    $c->require_capability( export_from_project => { source_project => $source } );

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
      or $c->detach( '/error/forbidden', ["Cannot create project with empty name!"] );

    my $is_public = !!$c->req->params->get('is_public');

    # TODO keep form input
    if ( not( $is_public or $c->has_capability('create_private_project') ) ) {
        $c->messages->error("You're not allowed to create private projects");
        $c->detach('/error/forbidden');
    }

    my $projects = $c->model('DB::Project');

    my $project = $c->stash->{project} = $c->model('DB::Project')->new_result(
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

    # TODO keep form input
    if ( $projects->search( { url_name_fc => $project->url_name_fc } )->exists ) {
        $c->messages->error("Project name is already in use");
        $c->redirect_detach( $c->uri_for('/') );
    }

    $project->insert();

    my $exportable_projects = $c->forward('exportable_projects');

    $c->response->redirect(
        $c->project_uri( $self->action_for( @$exportable_projects > 0 ? 'get_import' : 'show' ) ) );
}

sub update : POST Chained('base') Args(0) RequiresCapability('update_project') {
    my ( $self, $c ) = @_;

    my $project = $c->stash->{project};

    $project->update(
        { description => $c->req->params->get('description') // $c->detach('/error/bad_request') } );

    $c->response->redirect( $c->project_uri('/project/settings') );
}

sub archive : POST Chained('base') Args(0) RequiresCapability('archive_project') {
    my ( $self, $c ) = @_;

    $c->stash->{project}->archive();

    $c->response->redirect( $c->project_uri('/project/show') );
}

sub unarchive : POST Chained('base') Args(0) RequiresCapability('unarchive_project') {
    my ( $self, $c ) = @_;

    $c->stash->{project}->unarchive();

    $c->response->redirect( $c->project_uri('/project/show') );
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

    $project->update( { is_public => !!$c->req->params->get('public') } );

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
