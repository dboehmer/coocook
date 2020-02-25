package Coocook::Controller::Group::Member;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Group::Member - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub index : GET HEAD Chained('/group/base') PathPart('members') Args(0)
  RequiresCapability('view_group_members') {
    my ( $self, $c ) = @_;

    my $group = $c->stash->{group};

    my @groups_users = $group->search_related(
        groups_users => undef,
        { prefetch => 'user', order_by => 'user.name_fc' }
    )->all;

    for (@groups_users) {
        my $group_user = $_;

        $_ = $group_user->as_hashref;

        $_->{user_url} = $c->uri_for_action( '/user/show', [ $group_user->user->name ] );

        if ( $group_user->role eq 'admin' ) {
            $_->{transfer_ownership_url} =
              $c->uri_for( $self->action_for('make_owner'), [ $group->name, $group_user->user->name ] );
        }

        if ( $c->has_capability( remove_user_from_group => { membership => $group_user } ) ) {
            $_->{remove_url} =
              $c->uri_for( $self->action_for('remove'), [ $group->name, $group_user->user->name ] );
        }
    }

    if ( my @other_users = $group->users_without_membership->sorted->hri->all ) {
        $c->stash(
            roles       => [ grep { $_ ne 'owner' } $c->model('Authorization')->group_roles ],
            add_url     => $c->uri_for( $self->action_for('add'), [ $group->name ] ),
            other_users => \@other_users,
        );
    }

    $c->stash( groups_users => \@groups_users );
}

sub add : POST Chained('/group/base') Args(0) Public    # custom requires_capability() call below
{
    my ( $self, $c ) = @_;

    my $group = $c->stash->{group};

    my $name = $c->req->params->get('name');
    my $role = $c->req->params->get('role');

    my $user = $c->model('DB::User')->find( { name => $name } ) || $c->detach('/error/bad_request');

    $c->requires_capability( add_user_to_group => { role => $role, user_object => $user } );

    $group->create_related(
        groups_users => {
            user => $user->id,
            role => $role
        }
    );

    $c->detach('redirect');
}

sub base : Chained('/group/base') PathPart('member') CaptureArgs(1) {
    my ( $self, $c, $name ) = @_;

    $c->stash->{membership} =
      $c->stash->{group}
      ->find_related( groups_users => { 'user.name' => $name }, { prefetch => 'user' } )
      || $c->detach('/error/bad_request');
}

sub make_owner : POST Chained('base') PathPart('make_owner') Args(0)
  RequiresCapability('transfer_group_ownership') {
    my ( $self, $c ) = @_;

    $c->stash->{membership}->make_owner;
    $c->detach('redirect');
}

sub remove : POST Chained('base') Args(0) RequiresCapability('remove_user_from_group') {
    my ( $self, $c ) = @_;

    $c->stash->{membership}->delete();
    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->uri_for( $self->action_for('index'), [ $c->stash->{group}->name ] ) );
}

__PACKAGE__->meta->make_immutable;

1;
