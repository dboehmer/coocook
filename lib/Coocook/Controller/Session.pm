package Coocook::Controller::Session;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub login : GET Local Args(0) {
    my ( $self, $c ) = @_;
}

sub post_login : POST Path('/login') Args(0) {
    my ( $self, $c ) = @_;

    my $username = $c->req->param('username');
    my $password = $c->req->param('password');

    if ( $username eq 'coocook' ) {
        $c->session( username => $username );
        $c->response->redirect( $c->uri_for('/') );
    }
    else {
        $c->detach('logout');
    }
}

sub logout : POST Local Args(0) {
    my ( $self, $c ) = @_;

    delete $c->session->{username};

    $c->response->redirect( $c->uri_for_action('/login') );
}

1;
