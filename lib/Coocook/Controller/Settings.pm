package Coocook::Controller::Settings;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub settings_base : Chained('/base') PathPart('settings') CaptureArgs(0) { }

sub settings : GET Chained('settings_base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        change_display_name_url => $c->uri_for( $self->action_for('change_display_name') ),
        change_password_url     => $c->uri_for( $self->action_for('change_password') ),
    );
}

sub change_display_name : POST Chained('settings_base') Args(0) {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user};

    $user->update( { display_name => $c->req->params->get('display_name') } );

    $c->response->redirect( $c->uri_for( $self->action_for('settings') ) );
}

sub change_password : POST Chained('settings_base') Args(0) {
    my ( $self, $c ) = @_;

    my $user = $c->user
      or die;

    $user->check_password( $c->req->params->get('old_password') )
      or die "wrong old password";    # TODO error handling

    my $new_password = $c->req->params->get('new_password');

    $c->req->params->get('new_password2') eq $new_password
      or die "new passwords don't match";    # TODO error handling

    $user->update( { password => $new_password } );

    $c->response->redirect( $c->uri_for( $self->action_for('settings') ) );
}

__PACKAGE__->meta->make_immutable;

1;
