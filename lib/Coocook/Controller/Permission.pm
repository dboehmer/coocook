package Coocook::Controller::Permission;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub index : GET HEAD Chained('/project/submenu') PathPart('permissions') Args(0)
  RequiresCapability('view_project_permissions') {
    my ( $self, $c ) = @_;

    my @permissions;

    {
        my $groups_projects = $c->project->groups_projects->search( undef, { prefetch => 'group' } );

        while ( my $group_project = $groups_projects->next ) {
            push @permissions, {
                role      => $group_project->role,
                sort_key  => $group_project->group->name_fc,
                group     => $group_project->group,
                group_url => $c->uri_for_action( '/group/show', [ $group_project->group->name ] ),

                edit_url => $c->has_capability( 'edit_project_permission',
                    { permission => $group_project, role => 'viewer' } )
                ? $c->project_uri( $self->action_for('edit'), $group_project->group->name )
                : undef,

                revoke_url => $c->has_capability( 'revoke_project_permission', { permission => $group_project } )
                ? $c->project_uri( $self->action_for('revoke'), $group_project->group->name )
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

                edit_url => $c->has_capability(
                    edit_project_permission => { permission => $project_user, role => 'viewer' }
                  )
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

    {
        my $other_users  = $c->project->users_without_permission;
        my $other_groups = $c->project->groups_without_permission;

        my @other_identities =
          sort { $a->{name_fc} cmp $b->{name_fc} }
          ( $other_users->hri->all, map { $_->{is_group} = 1; $_ } $other_groups->hri->all );

        if ( @other_identities > 0 ) {
            $c->stash(
                add_permission_url => $c->project_uri( $self->action_for('add') ),
                other_identities   => \@other_identities,
            );
        }
    }

    $c->stash(
        permissions => \@permissions,
        roles       => [ grep { $_ ne 'owner' } $c->model('Authorization')->project_roles ],
        template    => 'project/permissions.tt',
    );
}

sub add : POST Chained('/project/base') PathPart('permissions/add') Args(0)
  Public    # custom requires_capability() calls below
{
    my ( $self, $c ) = @_;

    my $role = $c->req->params->get('role');

    if ( my $group = $c->model('DB::Group')->find( { name => $c->req->params->get('id') } ) ) {
        $c->requires_capability( add_group_permission => { group => $group, role => $role } );

        $c->project->create_related(
            groups_projects => {
                group => $group->id,
                role  => $role,
            }
        );
    }
    elsif ( my $user = $c->model('DB::User')->find( { name => $c->req->params->get('id') } ) ) {
        $c->requires_capability( add_user_permission => { role => $role, user_object => $user } );

        $c->project->create_related(
            projects_users => {
                user => $user->id,
                role => $role,
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
      || $project->groups_projects->search( { 'group.name' => $id }, { prefetch => 'group' } )->single
      || $c->detach('/error/bad_request');
}

sub edit : POST Chained('base') PathPart('edit') Args(0)
  Public    # custom requires_capability() call below
{
    my ( $self, $c ) = @_;

    my $role = $c->req->params->get('role');

    $c->requires_capability( edit_project_permission => { role => $role } );

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
