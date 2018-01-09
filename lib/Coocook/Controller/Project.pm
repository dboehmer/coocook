package Coocook::Controller::Project;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

Coocook::Controller::Project - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 base

Chain action that captures the project ID and stores the
C<Result::Project> object in the stash.

=cut

sub base : Chained('/enforce_ssl') PathPart('project') CaptureArgs(1) {
    my ( $self, $c, $url_name ) = @_;

    if ( my $project = $c->model('DB::Project')->find_by_url_name($url_name) ) {
        if ( $c->req->method eq 'GET' and $url_name ne $project->url_name ) {

            # TODO redirect to same URL with $url_name in exact case
            # e.g. /project/fOO => /project/Foo (for url_name 'Foo' in database)
        }

        $c->stash( project => $project );
    }
    else {
        $c->redirect_detach( $c->uri_for( '/', { error => "Project not found" } ) );
    }
}

=head2 index

=cut

sub edit : GET Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

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
        permissions_url      => $c->project_uri('/project/permissions'),
        settings_url         => $c->project_uri('/project/settings'),
        edit_dishes_url      => $c->project_uri('/project/edit_dishes'),
        dish_create_url      => $c->project_uri('/dish/create'),
        dish_from_recipe_url => $c->project_uri('/dish/from_recipe'),
        meal_create_url      => $c->project_uri('/meal/create'),
    );
}

sub permissions : GET Chained('base') PathPart('permissions') Args(0) {
    my ( $self, $c ) = @_;

    my @permissions;

    {
        my $projects_users = $c->project->projects_users->search( undef, { prefetch => 'user' } );

        while ( my $project_user = $projects_users->next ) {
            push @permissions,
              {
                role     => $project_user->role,
                user     => $project_user->user,
                user_url => $c->uri_for_action( '/user/show', [ $project_user->user->name ] ),
                edit_url => $project_user->role eq 'owner' ? undef
                : $c->project_uri( $self->action_for('edit_permission'), $project_user->user->name ),
                make_owner_url => $project_user->role eq 'admin'
                ? $c->project_uri( $self->action_for('make_owner'), $project_user->user->name )
                : undef,
                revoke_url => $project_user->role eq 'owner' ? undef
                : $c->project_uri( $self->action_for('revoke_permission'), $project_user->user->name ),
              };
        }
    }

    if ( my @other_users = $c->project->users_without_permission->all ) {
        $c->stash(
            add_permission_url => $c->project_uri( $self->action_for('add_permission') ),
            other_users        => \@other_users,
        );
    }

    $c->stash(
        permissions => \@permissions,
        roles       => [qw< admin user >],    # TODO define roles, define them globally
        title       => "Permissions",
    );
}

sub add_permission : POST Chained('base') PathPart('permissions/add') Args(0) {
    my ( $self, $c ) = @_;

    my $user = $c->model('DB::User')->find( { name => $c->req->params->get('user') } );

    $c->project->create_related(
        projects_users => {
            user => $user->id,
            role => $c->req->params->get('role'),
        }
    );

    $c->response->redirect( $c->project_uri( $self->action_for('permissions') ) );
}

sub permission_base : Chained('base') PathPart('permissions') CaptureArgs(1) {
    my ( $self, $c, $username ) = @_;

    $c->stash->{permission} =
      $c->project->projects_users->search( { 'user.name' => $username }, { prefetch => 'user' } )
      ->single;
}

sub edit_permission : POST Chained('permission_base') PathPart('edit') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{permission}->update( { role => $c->req->params->get('role') } );

    $c->response->redirect( $c->project_uri( $self->action_for('permissions') ) );
}

sub make_owner : POST Chained('permission_base') PathPart('make_owner') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{permission}->make_owner;

    $c->response->redirect( $c->project_uri( $self->action_for('permissions') ) );
}

sub revoke_permission : POST Chained('permission_base') PathPart('revoke') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{permission}->delete;

    $c->response->redirect( $c->project_uri( $self->action_for('permissions') ) );
}

sub settings : GET Chained('base') PathPart('settings') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        rename_url            => $c->project_uri('/project/rename'),
        visibility_url        => $c->project_uri('/project/visibility'),
        delete_url            => $c->project_uri('/project/delete'),
        deletion_confirmation => $c->config->{project_deletion_confirmation},
    );

    $c->escape_title( "Project settings" => $c->project->name );
}

sub get_import : GET Chained('base') PathPart('import') Args(0) {   # import() already used by 'use'
    my ( $self, $c ) = @_;

    my @projects = $c->project->other_projects->all;

    my $importer = $c->model('Importer');

    $c->stash(
        projects        => \@projects,
        properties      => $importer->properties,
        properties_json => $importer->properties_json,
        import_url      => $c->project_uri('/project/post_import'),
        template        => 'project/import.tt',
        title           => "Import",
    );
}

sub post_import : POST Chained('base') PathPart('import') Args(0) { # import() already used by 'use'
    my ( $self, $c ) = @_;

    my $importer = $c->model('Importer');
    my $source   = $c->model('DB::Project')->find( $c->req->params->get('source_project') );
    my $target   = $c->project;

    # extract properties selected in form
    my @properties =
      grep { $c->req->params->get("property_$_") } map { $_->{key} } @{ $importer->properties };

    $importer->import_data( $source => $target, \@properties );

    $c->detach( redirect => [$target] );
}

sub edit_dishes : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $project = $c->project;

    # filter selected IDs from possible dish IDs
    my @dish_ids =
      grep { $c->req->params->get("dish$_") } $project->meals->dishes->get_column('id')->all;

    # select dishes from valid ID list
    my $dishes = $c->model('DB::Dish')->search( { id => { -in => \@dish_ids } } );

    if ( $c->req->params->get('update') ) {
        if ( $c->req->params->get('edit_comment') ) {
            $dishes->update( { comment => $c->req->params->get('new_comment') } );
        }

        if ( $c->req->params->get('edit_servings') ) {
            for my $dish ( $dishes->all ) {
                $dish->recalculate( $c->req->params->get('new_servings') );
            }
        }
    }
    elsif ( $c->req->params->get('delete') ) {
        $dishes->delete_all();
    }

    $c->detach( redirect => [$project] );
}

sub create : POST Chained('/enforce_ssl') PathPart('project/create') Args(0) {
    my ( $self, $c ) = @_;

    my $name = $c->req->params->get('name');

    length $name > 0
      or
      $c->redirect_detach( $c->uri_for( '/', { error => "Cannot create project with empty name!" } ) );

    $c->txn_do(
        sub {
            my $project = $c->model('DB::Project')->create(
                {
                    name  => $c->req->params->get('name'),
                    owner => $c->user->id,

                    # project will be public unless $c->user has permission for private projects
                    is_public => $c->user->has_permission('make_project_private') ? 0 : 1,
                }
            );

            $project->create_related(
                projects_users => {
                    user => $c->user->id,
                    role => 'owner',
                }
            );

            $c->response->redirect(
                $c->uri_for_action( $self->action_for('get_import'), [ $project->url_name ] ) );
        }
    );
}

sub rename : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $project = $c->stash->{project};

    $project->update( { name => $c->req->params->get('name') } );

    $c->response->redirect( $c->project_uri('/project/settings') );
}

sub visibility : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $project = $c->stash->{project};

    $project->update( { is_public => $c->req->params->get('public') ? 1 : 0 } );

    $c->response->redirect( $c->project_uri('/project/settings') );
}

sub delete : POST Chained('base') Args(0) {
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
