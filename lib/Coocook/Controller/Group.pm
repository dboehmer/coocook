package Coocook::Controller::Group;

use utf8;
use feature 'fc';    # Perl v5.16

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

    {
        my @errors;

        if ( $name !~ m/ \A [0-9a-zA-Z_]+ \Z /x ) {
            push @errors, "The group’s name must not contain other characters than 0-9, a-z, A-Z or _.";
        }
        else {
            my $name_fc = fc($name);

            !$c->model('DB::Group')->exists( { name_fc => $name_fc } )
              and !$c->model('DB::User')->exists( { name_fc => $name_fc } )
              and $c->model('DB::BlacklistUsername')->is_username_ok($name)
              or push @errors, "name is not available";
        }

        if (@errors) {
            $c->messages->error($_) for @errors;

            $c->stash(
                template   => 'settings/groups.tt',
                last_input => { name => $name },
            );

            $c->go('/settings/groups');
        }
    }

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

    my @groups_projects =
      $group->search_related( groups_projects => undef, { prefetch => 'project' } )->all;

    for (@groups_projects) {
        my $group_project = $_;

        $_ = $group_project->as_hashref;

        $_->{project_url} = $c->uri_for_action( '/project/show', [ $group_project->project->url_name ] );
    }

    $c->has_capability('delete_group')
      and $c->stash( delete_url => $c->uri_for( $self->action_for('delete'), [ $group->name ] ) );

    $c->stash(
        groups_users    => \@groups_users,
        groups_projects => \@groups_projects,
        update_url      => $c->uri_for( $self->action_for('update'), [ $group->name ] ),
        members_url     => $c->uri_for_action( '/group/member/index', [ $group->name ] ),
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

sub delete : POST Chained('base') Args(0) RequiresCapability('delete_group') {
    my ( $self, $c ) = @_;

    $c->stash->{group}->delete();

    $c->redirect_detach(
        $c->uri_for_action( $c->has_capability('admin_view') ? '/admin/groups' : '/settings/index' ) );
}

sub leave : POST Chained('base') Args(0) RequiresCapability('leave_group') {
    my ( $self, $c ) = @_;

    $c->stash->{group}->delete_related( groups_users => { user => $c->user->id } );

    $c->redirect_detach( $c->uri_for_action('/settings/groups') );
}

sub redirect : Private {
    my ( $self, $c, $group ) = @_;

    $group ||= $c->stash->{group};

    $c->redirect_detach( $c->uri_for( $self->action_for('show'), [ $group->name ] ) );
}

__PACKAGE__->meta->make_immutable;

1;
