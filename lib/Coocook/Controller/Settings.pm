package Coocook::Controller::Settings;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

__PACKAGE__->config( namespace => '' );

# need to use different name than just 'base'
# because controller is explicitly set to namespace '' like Controller::Root
sub settings_base : Chained('/base') PathPart('settings') CaptureArgs(0) { }

sub settings : GET HEAD Chained('settings_base') PathPart('') Args(0)
  RequiresCapability('view_user_settings') {
    my ( $self, $c ) = @_;

    $c->stash(
        change_display_name_url => $c->uri_for( $self->action_for('change_display_name') ),
        change_password_url     => $c->uri_for( $self->action_for('change_password') ),
    );
}

sub change_display_name : POST Chained('settings_base') Args(0)
  RequiresCapability('change_display_name') {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user};

    $user->update( { display_name => $c->req->params->get('display_name') } );

    $c->response->redirect( $c->uri_for( $self->action_for('settings') ) );
}

sub change_password : POST Chained('settings_base') Args(0) RequiresCapability('change_password') {
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

    $c->response->redirect( $c->uri_for( $self->action_for('settings') ) );
}

sub redirect : Private {
    my ( $self, $c, $query ) = @_;

    $c->response->redirect( $c->uri_for( $self->action_for('settings'), $query || () ) );
}

__PACKAGE__->meta->make_immutable;

1;
