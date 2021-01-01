package Coocook::Controller::Settings;

use utf8;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub base : Chained('/base') PathPart('settings') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        submenu_items => [
            { action => 'settings/account',       text => "Account" },
            { action => 'settings/organizations', text => "Organizations" },
            { action => 'settings/projects',      text => "Projects" },
        ],
    );
}

sub index : GET HEAD Chained('base') PathPart('') Args(0) Public {
    my ( $self, $c ) = @_;

    $c->redirect_detach( $c->uri_for( $self->action_for('account') ) );
}

sub account : GET HEAD Chained('base') Args(0) RequiresCapability('view_account_settings') {
    my ( $self, $c ) = @_;

    $c->user->new_email_fc
      and $c->stash( cancel_email_change_url => $c->uri_for_action('/settings/change_email/cancel') );

    $c->stash(
        profile_url             => $c->uri_for_action( '/user/show', [ $c->user->name ] ),
        change_display_name_url => $c->uri_for( $self->action_for('change_display_name') ),
        change_password_url     => $c->uri_for( $self->action_for('change_password') ),
        change_email_url        => $c->uri_for_action('/settings/change_email/request'),
        recovery_url            => $c->uri_for_action( '/user/recover', { email => $c->user->email_fc } ),
    );
}

sub change_display_name : POST Chained('base') Args(0) RequiresCapability('change_display_name') {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user};

    $user->update( { display_name => $c->req->params->get('display_name') } );

    $c->response->redirect( $c->uri_for( $self->action_for('index') ) );
}

sub change_password : POST Chained('base') Args(0) RequiresCapability('change_password') {
    my ( $self, $c ) = @_;

    my $user = $c->user
      or die;

    $user->check_password( $c->req->params->get('current_password') )
      or $c->detach( redirect => [ { error => "current password doesn’t match" } ] );

    my $new_password = $c->req->params->get('new_password');

    length $new_password > 0
      or $c->detach( redirect => [ { error => "new password must not be empty" } ] );

    $c->req->params->get('new_password2') eq $new_password
      or $c->detach( redirect => [ { error => "new passwords don’t match" } ] );

    # TODO this should probably logout all other existing sessions of this user!
    $user->update( { password => $new_password } );

    $c->messages->info("Your password has been changed.");

    $c->visit( '/email/password_changed', [$user] );

    $c->response->redirect( $c->uri_for( $self->action_for('index') ) );
}

sub organizations : GET HEAD Chained('base') Args(0) RequiresCapability('view_user_organizations') {
    my ( $self, $c ) = @_;

    my @organizations_users =
      $c->user->search_related( organizations_users => undef, { prefetch => 'organization' } )->all;

    for (@organizations_users) {
        my $organization_user = $_;
        my $organization      = $_->organization;

        $_ = $organization_user->as_hashref(
            organization     => $organization,
            organization_url => $c->uri_for_action( '/organization/show', [ $organization->name ] ),
            leave_url        => $c->uri_for_action_if_permitted(
                '/organization/leave',
                { organization => $organization },
                [ $organization->name ]
            ),
        );
    }

    $c->stash(
        create_organization_url => $c->uri_for_action('/organization/create'),
        organizations_users     => \@organizations_users,
    );
}

sub projects : GET HEAD Chained('base') RequiresCapability('view_user_projects') {
    my ( $self, $c ) = @_;

    my $projects_users = $c->user->projects_users;

    my @projects = $projects_users->related_resultset('project')->search(
        undef,
        {
            '+columns' => { role => $projects_users->me('role') },
        }
    )->hri->sorted->all;

    for my $project (@projects) {
        $project->{url} = $c->uri_for_action( '/project/show', [ $project->{id}, $project->{url_name} ] );
    }

    $c->stash( projects => \@projects );
}

sub redirect : Private {
    my ( $self, $c, $message ) = @_;

    $c->messages->add($message);

    $c->response->redirect( $c->uri_for( $self->action_for('index') ) );
}

__PACKAGE__->meta->make_immutable;

1;
