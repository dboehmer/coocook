package Coocook::Controller::Session;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub login : GET Chained('/enforce_ssl') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        post_login_url => $c->uri_for( $self->action_for('post_login') ),
        title          => "Login",
    );
}

sub post_login : POST Chained('/enforce_ssl') PathPart('login') Args(0) {
    my ( $self, $c ) = @_;

    my $username = $c->req->param('username');
    my $password = $c->req->param('password');

    my $user = $c->authenticate(
        {
            name           => $username,
            password_hash  => $password,
            email_verified => { '!=' => undef }
        }
    );

    if ($user) {
        $c->response->redirect( $c->uri_for_action('/index') );
    }
    else {
        $c->logout();
        $c->response->redirect( $c->uri_for_action( '/login', { error => "Login failed!" } ) );
    }
}

sub logout : POST Chained('/enforce_ssl') Args(0) {
    my ( $self, $c ) = @_;

    $c->logout();

    $c->response->redirect( $c->uri_for_action('/index') );
}

1;
