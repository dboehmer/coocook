package Coocook::Controller::Organization::Member;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Organization::Member - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub index : GET HEAD Chained('/organization/base') PathPart('members') Args(0)
  RequiresCapability('view_organization_members') {
    my ( $self, $c ) = @_;

    my $organization = $c->stash->{organization};

    my @organizations_users = $organization->search_related(
        organizations_users => undef,
        { prefetch => 'user', order_by => 'user.name_fc' }
    )->all;

    for (@organizations_users) {
        my $organization_user = $_;

        $_ = $organization_user->as_hashref( user => $organization_user->user );

        $_->{user_url} = $c->uri_for_action( '/user/show', [ $organization_user->user->name ] );

        $_->{transfer_ownership_url} = $c->uri_for_action_if_permitted(
            $self->action_for('make_owner'),
            { membership => $organization_user },
            [ $organization->name, $organization_user->user->name ]
        );

        $_->{remove_url} = $c->uri_for_action_if_permitted(
            $self->action_for('remove'),
            { membership => $organization_user },
            [ $organization->name, $organization_user->user->name ]
        );

        # can't use uri_for_action_if_permitted() because action has non-declarative check
        $c->has_capability(
            edit_organization_membership => { membership => $organization_user, role => 'member' } )
          or next;

        $_->{edit_url} =
          $c->uri_for( $self->action_for('edit'), [ $organization->name, $organization_user->user->name ] );
    }

    if ( my @other_users = $organization->users_without_membership->sorted->hri->all ) {
        $c->stash(
            add_url     => $c->uri_for( $self->action_for('add'), [ $organization->name ] ),
            other_users => \@other_users,
        );
    }

    $c->stash(
        organization_url    => $c->uri_for_action( '/organization/show', [ $organization->name ] ),
        organizations_users => \@organizations_users,
        roles               => [ grep { $_ ne 'owner' } $c->model('Authorization')->organization_roles ],
        template            => 'organization/members.tt',
    );
}

sub add : POST Chained('/organization/base') Args(0) CustomAuthz {
    my ( $self, $c ) = @_;

    my $organization = $c->stash->{organization};

    my $name = $c->req->params->get('name');
    my $role = $c->req->params->get('role');

    my $user = $c->model('DB::User')->find( { name => $name } ) || $c->detach('/error/bad_request');

    $c->require_capability( add_user_to_organization => { role => $role, user_object => $user } );

    $organization->create_related(
        organizations_users => {
            user_id => $user->id,
            role    => $role
        }
    );

    $c->detach('redirect');
}

sub base : Chained('/organization/base') PathPart('member') CaptureArgs(1) {
    my ( $self, $c, $name ) = @_;

    $c->stash->{membership} =
      $c->stash->{organization}
      ->find_related( organizations_users => { 'user.name' => $name }, { prefetch => 'user' } )
      || $c->detach('/error/bad_request');
}

sub edit : POST Chained('base') Args(0) CustomAuthz {
    my ( $self, $c ) = @_;

    my $role = $c->req->params->get('role');

    $c->require_capability( edit_organization_membership => { role => $role } );

    $c->stash->{membership}->update( { role => $role } );

    $c->detach('redirect');
}

sub make_owner : POST Chained('base') PathPart('make_owner') Args(0)
  RequiresCapability('transfer_organization_ownership') {
    my ( $self, $c ) = @_;

    $c->stash->{membership}->make_owner;
    $c->detach('redirect');
}

sub remove : POST Chained('base') Args(0) RequiresCapability('remove_user_from_organization') {
    my ( $self, $c ) = @_;

    $c->stash->{membership}->delete();
    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect(
        $c->uri_for( $self->action_for('index'), [ $c->stash->{organization}->name ] ) );
}

__PACKAGE__->meta->make_immutable;

1;
