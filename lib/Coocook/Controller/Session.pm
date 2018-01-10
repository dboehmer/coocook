package Coocook::Controller::Session;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub login : GET Chained('/base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        username       => $c->req->params->get('username'),
        post_login_url => $c->uri_for( $self->action_for('post_login') ),
        recover_url    => $c->uri_for_action('/user/recover'),
        title          => "Login",
    );
}

sub post_login : POST Chained('/base') PathPart('login') Args(0) {
    my ( $self, $c ) = @_;

    my $user = $c->authenticate(
        {
            name           => $c->req->params->get('username'),
            password_hash  => $c->req->params->get('password'),
            email_verified => { '!=' => undef },
        }
    );

    if ($user) {
        $c->response->redirect( $c->uri_for_action('/index') );
    }
    else {
        $c->logout();
        $c->response->redirect(
            $c->uri_for_action(
                '/login',
                {
                    error    => "Login failed!",
                    username => $c->req->params->get('username'),
                }
            )
        );
    }
}

sub logout : POST Chained('/base') Args(0) {
    my ( $self, $c ) = @_;

    $c->logout();

    $c->response->redirect( $c->uri_for_action('/index') );
}

1;
