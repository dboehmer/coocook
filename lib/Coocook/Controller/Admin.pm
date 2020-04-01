package Coocook::Controller::Admin;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub base : Chained('/base') PathPart('admin') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        submenu_items => [
            { action => 'admin/faq/index',     text => "FAQ" },
            { action => 'admin/organizations', text => "Organizations" },
            { action => 'admin/projects',      text => "Projects" },
            { action => 'admin/terms/index',   text => "Terms" },
            { action => 'admin/user/index',    text => "Users" },
        ]
    );
}

sub index : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('admin_view') {
    my ( $self, $c ) = @_;

    my $max_organizations = 5;
    my $max_projects      = 10;
    my $max_users         = 10;

    my @organizations = $c->model('DB::Organization')
      ->search( undef, { order_by => { -desc => 'created' }, rows => $max_organizations } )->hri->all;

    $_->{url} = $c->uri_for_action( '/organization/show', [ $_->{name} ] ) for @organizations;

    my @projects = $c->model('DB::Project')
      ->search( undef, { order_by => { -desc => 'created' }, rows => $max_projects } )->hri->all;

    $_->{url} = $c->uri_for_action( '/project/show', [ $_->{id}, $_->{url_name} ] ) for @projects;

    my @users = $c->model('DB::User')
      ->search( undef, { order_by => { -desc => 'created' }, rows => $max_users } )->hri->all;

    $_->{url} = $c->uri_for_action( '/admin/user/show', [ $_->{name} ] ) for @users;

    $c->stash(
        organizations => \@organizations,
        projects      => \@projects,
        users         => \@users,

        organizations_url => $c->uri_for( $self->action_for('organizations') ),
        projects_url      => $c->uri_for( $self->action_for('projects') ),
        users_url         => $c->uri_for_action('/admin/user/index'),
    );

}

sub organizations : GET HEAD Chained('base') Args(0) RequiresCapability('admin_view') {
    my ( $self, $c ) = @_;

    my @organizations = $c->model('DB::Organization')->sorted->hri->all;

    for my $organization (@organizations) {
        $organization->{url} = $c->uri_for_action( '/organization/show', [ $organization->{name} ] );
    }

    $c->stash( organizations => \@organizations );
}

sub projects : GET HEAD Chained('base') Args(0) RequiresCapability('admin_view') {
    my ( $self, $c ) = @_;

    # we expect every users to have >=1 projects
    # so better not preload 1:n relationship 'users'
    my @projects = $c->model('DB::Project')->sorted->hri->all;

    my %users = map { $_->{id} => $_ } $c->model('DB::User')->with_projects_count->hri->all;

    for my $project (@projects) {
        $project->{owner} = $users{ $project->{owner_id} } || die;
        $project->{url}   = $c->uri_for_action( '/project/show', [ $project->{id}, $project->{url_name} ] );
    }

    for my $user ( values %users ) {
        $user->{url} = $c->uri_for_action( '/user/show', [ $user->{name} ] );
    }

    $c->stash( projects => \@projects );
}

__PACKAGE__->meta->make_immutable;

1;
