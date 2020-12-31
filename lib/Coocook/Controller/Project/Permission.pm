package Coocook::Controller::Permission;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub index : GET HEAD Chained('/project/submenu') PathPart('permissions') Args(0)
  RequiresCapability('view_project_permissions') {
    my ( $self, $c ) = @_;

    my @permissions;

    {
        my $organizations_projects =
          $c->project->organizations_projects->search( undef, { prefetch => 'organization' } );

        while ( my $organization_project = $organizations_projects->next ) {
            push @permissions, {
                role             => $organization_project->role,
                sort_key         => $organization_project->organization->name_fc,
                organization     => $organization_project->organization,
                organization_url =>
                  $c->uri_for_action( '/organization/show', [ $organization_project->organization->name ] ),

                edit_url => $c->has_capability(
                    edit_organization_permission => { permission => $organization_project, role => 'viewer' }
                  )
                ? $c->project_uri( $self->action_for('edit'), $organization_project->organization->name )
                : undef,

                revoke_url =>
                  $c->has_capability( 'revoke_project_permission', { permission => $organization_project } )
                ? $c->project_uri( $self->action_for('revoke'), $organization_project->organization->name )
                : undef,
            };
        }
    }

    {
        my $projects_users = $c->project->projects_users->search( undef, { prefetch => 'user' } );

        while ( my $project_user = $projects_users->next ) {
            push @permissions, {
                role     => $project_user->role,
                sort_key => $project_user->user->name_fc,
                user     => $project_user->user,
                user_url => $c->uri_for_action( '/user/show', [ $project_user->user->name ] ),

                edit_url =>
                  $c->has_capability( edit_user_permission => { permission => $project_user, role => 'viewer' } )
                ? $c->project_uri( $self->action_for('edit'), $project_user->user->name )
                : undef,

                make_owner_url =>
                  $c->has_capability( 'transfer_project_ownership', { permission => $project_user } )
                ? $c->project_uri( $self->action_for('make_owner'), $project_user->user->name )
                : undef,

                revoke_url => $c->has_capability( 'revoke_project_permission', { permission => $project_user } )
                ? $c->project_uri( $self->action_for('revoke'), $project_user->user->name )
                : undef,
            };
        }
    }

    @permissions = sort { $a->{sort_key} cmp $b->{sort_key} } @permissions;

    if ( $c->has_capability('edit_project_permissions') ) {
        my $other_users         = $c->project->users_without_permission;
        my $other_organizations = $c->project->organizations_without_permission;

        my @other_identities =
          sort { $a->{name_fc} cmp $b->{name_fc} }
          ( $other_users->hri->all, map { $_->{is_organization} = 1; $_ } $other_organizations->hri->all );

        @other_identities > 0
          and $c->stash( other_identities => \@other_identities );

        $c->stash( add_permission_url => $c->project_uri( $self->action_for('add') ) );
    }

    $c->stash(
        permissions => \@permissions,
        roles       => [ grep { $_ ne 'owner' } $c->model('Authorization')->project_roles ],
        template    => 'project/permissions.tt',
    );
}

sub add : POST Chained('/project/base') PathPart('permissions/add') Args(0) CustomAuthz {
    my ( $self, $c ) = @_;

    my $id   = $c->req->params->get('id');
    my $role = $c->req->params->get('role');

    if ( my $organization = $c->model('DB::Organization')->find( { name => $id } ) ) {
        $c->require_capability(
            add_organization_permission => { organization => $organization, role => $role } );

        $c->project->create_related(
            organizations_projects => {
                organization_id => $organization->id,
                role            => $role,
            }
        );
    }
    elsif ( my $user = $c->model('DB::User')->find( { name => $id } ) ) {
        $c->require_capability( add_user_permission => { role => $role, user_object => $user } );

        $c->project->create_related(
            projects_users => {
                user_id => $user->id,
                role    => $role,
            }
        );
    }
    else { $c->detach('/error/bad_request') }

    $c->detach('redirect');
}

sub base : Chained('/project/base') PathPart('permissions') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    my $project = $c->project;

    $c->stash->{permission} =
      $project->projects_users->search( { 'user.name' => $id }, { prefetch => 'user' } )->single
      || $project->organizations_projects->search( { 'organization.name' => $id },
        { prefetch => 'organization' } )->single
      || $c->detach('/error/bad_request');
}

sub edit : POST Chained('base') PathPart('edit') Args(0) CustomAuthz {
    my ( $self, $c ) = @_;

    my $role = $c->req->params->get('role');

    $c->require_capability( edit_project_permission => { role => $role } );

    $c->stash->{permission}->update( { role => $role } );

    $c->detach('redirect');
}

sub make_owner : POST Chained('base') PathPart('make_owner') Args(0)
  RequiresCapability('transfer_project_ownership') {
    my ( $self, $c ) = @_;

    $c->stash->{permission}->can('make_owner')
      or $c->detach('/error/bad_request');

    $c->stash->{permission}->make_owner;
    $c->detach('redirect');
}

sub revoke : POST Chained('base') PathPart('revoke') Args(0)
  RequiresCapability('revoke_project_permission') {
    my ( $self, $c ) = @_;

    $c->stash->{permission}->delete;
    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c, $query ) = @_;

    $c->response->redirect( $c->project_uri( $self->action_for('index') ) );
}

__PACKAGE__->meta->make_immutable;

1;
