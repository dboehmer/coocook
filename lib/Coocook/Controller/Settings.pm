package Coocook::Controller::Settings;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub base : Chained('/base') PathPart('settings') CaptureArgs(0) { }

sub index : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('view_user_settings') {
    my ( $self, $c ) = @_;

    my @groups_users = $c->user->search_related( groups_users => undef, { prefetch => 'group' } )->all;

    for (@groups_users) {
        my $group_user = $_;
        my $group      = $_->group;

        $_ = $group_user->as_hashref;

        $_->{group_url} = $c->uri_for_action( '/group/show', [ $group->name ] );

        if ( $c->has_capability( leave_group => { group => $group } ) ) {
            $_->{leave_url} = $c->uri_for_action( '/group/leave', [ $group->name ] );
        }
    }

    $c->stash(
        profile_url             => $c->uri_for_action( '/user/show', [ $c->user->name ] ),
        change_display_name_url => $c->uri_for( $self->action_for('change_display_name') ),
        change_password_url     => $c->uri_for( $self->action_for('change_password') ),
        create_group_url        => $c->uri_for_action('/group/create'),
        groups_users            => \@groups_users,
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

    $user->check_password( $c->req->params->get('old_password') )
      or $c->detach( redirect => [ { error => "old password doesn't match" } ] );

    my $new_password = $c->req->params->get('new_password');

    length $new_password > 0
      or $c->detach( redirect => [ { error => "new password must not be empty" } ] );

    $c->req->params->get('new_password2') eq $new_password
      or $c->detach( redirect => [ { error => "new passwords don't match" } ] );

    $user->update( { password => $new_password } );

    $c->visit( '/email/password_changed', [$user] );

    $c->response->redirect( $c->uri_for( $self->action_for('index') ) );
}

sub projects : GET HEAD Chained('base') {
    my ( $self, $c ) = @_;

    my @projects = $c->user->projects->sorted->hri->all;

    for my $project (@projects) {
        $project->{url} = $c->uri_for_action( '/project/show', [ $project->{url_name} ] );
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
