package Coocook::Controller::Session;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub login : GET Local Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        post_login_url => $c->uri_for( $self->action_for('post_login') ),
        title          => "Login",
    );
}

sub post_login : POST Path('/login') Args(0) {
    my ( $self, $c ) = @_;

    my $username = $c->req->param('username');
    my $password = $c->req->param('password');

    if ( $c->authenticate( { name => $username, password_hash => $password } ) ) {
        $c->response->redirect( $c->uri_for_action('/index') );
    }
    else {
        $c->logout();
        $c->response->redirect( $c->uri_for_action('/login') );
    }
}

sub logout : POST Local Args(0) {
    my ( $self, $c ) = @_;

    $c->logout();

    $c->response->redirect( $c->uri_for_action('/index') );
}

1;
