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
    }

    $c->stash( groups_users => \@groups_users );
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

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->uri_for( $self->action_for('index'), [ $c->stash->{group}->name ] ) );
}

__PACKAGE__->meta->make_immutable;

1;
