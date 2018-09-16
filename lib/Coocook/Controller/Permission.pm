package Coocook::Controller::Permission;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub index : GET HEAD Chained('/project/base') PathPart('permissions') Args(0)
  RequiresCapability('view_project_permissions') {
    my ( $self, $c ) = @_;

    my @permissions;

    {
        my $projects_users = $c->project->projects_users->search( undef, { prefetch => 'user' } );

        while ( my $project_user = $projects_users->next ) {
            push @permissions, {
                role     => $project_user->role,
                user     => $project_user->user,
                user_url => $c->uri_for_action( '/user/show', [ $project_user->user->name ] ),

                edit_url => $c->has_capability( 'edit_project_permission', { permission => $project_user } )
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

    if ( my @other_users = $c->project->users_without_permission->all ) {
        $c->stash(
            add_permission_url => $c->project_uri( $self->action_for('add') ),
            other_users        => \@other_users,
        );
    }

    $c->stash(
        permissions => \@permissions,
        roles       => [ grep { $_ ne 'owner' } $c->model('Authorization')->project_roles ],
        template    => 'project/permissions.tt',
    );
}

sub add : POST Chained('/project/base') PathPart('permissions/add') Args(0)
  RequiresCapability('create_project_permission') {
    my ( $self, $c ) = @_;

    my $user = $c->model('DB::User')->find( { name => $c->req->params->get('user') } );

    $c->project->create_related(
        projects_users => {
            user => $user->id,
            role => $c->req->params->get('role'),
        }
    );

    $c->detach('redirect');
}

sub base : Chained('/project/base') PathPart('permissions') CaptureArgs(1) {
    my ( $self, $c, $username ) = @_;

    $c->stash->{permission} =
      $c->project->projects_users->search( { 'user.name' => $username }, { prefetch => 'user' } )
      ->single
      or $c->detach('/error/not_found');
}

sub edit : POST Chained('base') PathPart('edit') Args(0)
  RequiresCapability('edit_project_permission') {
    my ( $self, $c ) = @_;

    my @applicable_roles = grep { $_ ne 'owner' } $c->model('Authorization')->project_roles;

    my $role = $c->req->params->get('role');

    if ( not grep { $_ eq $role } @applicable_roles ) {
        $c->detach('/error/bad_request');
    }

    $c->stash->{permission}->update( { role => $role } );

    $c->detach('redirect');
}

sub make_owner : POST Chained('base') PathPart('make_owner') Args(0)
  RequiresCapability('transfer_project_ownership') {
    my ( $self, $c ) = @_;

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
