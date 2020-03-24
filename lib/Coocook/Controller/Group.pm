package Coocook::Controller::Group;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use PerlX::Maybe;

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Group - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub create : POST Chained('/base') PathPart('group/create') Args(0)
  RequiresCapability('create_group') {
    my ( $self, $c ) = @_;

    my $name = $c->req->params->get('name');

    # TODO check uniqueness among users and groups

    my $group = $c->model('Groups')->create(
        name  => $name,
        owner => $c->user->id,
    );

    $c->forward( 'redirect', [$group] );
}

sub base : Chained('/base') PathPart('group') CaptureArgs(1) {
    my ( $self, $c, $name ) = @_;

    my $group = $c->model('Groups')->find_by_name($name) || $c->detach('/error/not_found');

    $c->redirect_canonical_case( 0 => $group->name );

    $c->stash( group => $group );
}

sub show : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('view_group') {
    my ( $self, $c ) = @_;

    my $group = $c->stash->{group};

    my @groups_users = $group->search_related( groups_users => undef, { prefetch => 'user' } )->all;

    for (@groups_users) {
        my $group_user = $_;

        $_ = $group_user->as_hashref;

        $_->{user_url} = $c->uri_for_action( '/user/show', [ $group_user->user->name ] );
    }

    $c->stash(
        groups_users => \@groups_users,
        update_url   => $c->uri_for( $self->action_for('update'), [ $group->name ] ),
    );
}

sub update : POST Chained('base') PathPart('') Args(0) RequiresCapability('edit_group') {
    my ( $self, $c ) = @_;

    my %cols = (
        maybe
          description_md => $c->req->params->get('description_md'),
        maybe display_name => $c->req->params->get('display_name'),
    );

    %cols
      and $c->stash->{group}->update( \%cols );

    $c->forward('redirect');
}

sub redirect : Private {
    my ( $self, $c, $group ) = @_;

    $group ||= $c->stash->{group};

    $c->redirect_detach( $c->uri_for( $self->action_for('show'), [ $group->name ] ) );
}

__PACKAGE__->meta->make_immutable;

1;
