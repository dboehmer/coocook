package Coocook::Controller::Organization;

use utf8;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use PerlX::Maybe;

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Organization - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub create : POST Chained('/base') PathPart('organization/create') Args(0)
  RequiresCapability('create_organization') {
    my ( $self, $c ) = @_;

    my $name          = $c->req->params->get('name');
    my $organizations = $c->model('Organizations');

    {
        my @errors;

        if ( not $organizations->name_valid($name) ) {
            push @errors, "The organization’s name must not contain other characters than 0-9, a-z, A-Z or _.";
        }
        elsif ( not $organizations->name_available($name) ) {
            push @errors, "name is not available";
        }

        if (@errors) {
            $c->messages->error($_) for @errors;

            $c->stash(
                template   => 'settings/organizations.tt',
                last_input => { name => $name },
            );

            $c->go('/settings/organizations');
        }
    }

    my $organization = $organizations->create(
        name     => $name,
        owner_id => $c->user->id,
    );

    $c->forward( 'redirect', [$organization] );
}

sub base : Chained('/base') PathPart('organization') CaptureArgs(1) {
    my ( $self, $c, $name ) = @_;

    my $organization =
      $c->model('Organizations')->find_by_name($name) || $c->detach('/error/not_found');

    $c->stash( organization => $organization );

    $c->redirect_canonical_case( 0 => $organization->name );
}

sub show : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('view_organization') {
    my ( $self, $c ) = @_;

    my $organization = $c->stash->{organization};

    my @organizations_users =
      $organization->search_related( organizations_users => undef, { prefetch => 'user' } )->all;

    for (@organizations_users) {
        my $organization_user = $_;

        $_ = $organization_user->as_hashref( user => $organization_user->user );

        $_->{user_url} = $c->uri_for_action( '/user/show', [ $organization_user->user->name ] );
    }

    my @organizations_projects =
      $organization->search_related( organizations_projects => undef, { prefetch => 'project' } )->all;

    for (@organizations_projects) {
        my $organization_project = $_;

        $_ = $organization_project->as_hashref( project => $organization_project->project );

        $_->{project_url} =
          $c->uri_for_action( '/project/show',
            [ $organization_project->project->id, $organization_project->project->url_name ] );
    }

    $c->stash(
        organizations_users    => \@organizations_users,
        organizations_projects => \@organizations_projects,
        update_url             =>
          $c->uri_for_action_if_permitted( $self->action_for('update'), [ $organization->name ] ),
        members_url =>
          $c->uri_for_action_if_permitted( '/organization/member/index', [ $organization->name ] ),
        delete_url =>
          $c->uri_for_action_if_permitted( $self->action_for('delete'), [ $organization->name ] ),
    );
}

sub update : POST Chained('base') PathPart('') Args(0) RequiresCapability('edit_organization') {
    my ( $self, $c ) = @_;

    my %cols = (
        maybe
          description_md => $c->req->params->get('description_md'),
        maybe display_name => $c->req->params->get('display_name'),
    );

    %cols
      and $c->stash->{organization}->update( \%cols );

    $c->forward('redirect');
}

sub delete : POST Chained('base') Args(0) RequiresCapability('delete_organization') {
    my ( $self, $c ) = @_;

    $c->stash->{organization}->delete();

    $c->redirect_detach(
        $c->uri_for_action( $c->has_capability('admin_view') ? '/admin/organizations' : '/settings/index' )
    );
}

sub leave : POST Chained('base') Args(0) RequiresCapability('leave_organization') {
    my ( $self, $c ) = @_;

    $c->stash->{organization}->delete_related( organizations_users => { user_id => $c->user->id } );

    $c->redirect_detach( $c->uri_for_action('/settings/organizations') );
}

sub redirect : Private {
    my ( $self, $c, $organization ) = @_;

    $organization ||= $c->stash->{organization};

    $c->redirect_detach( $c->uri_for( $self->action_for('show'), [ $organization->name ] ) );
}

__PACKAGE__->meta->make_immutable;

1;
