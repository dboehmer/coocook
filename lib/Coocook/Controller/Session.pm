package Coocook::Controller::Session;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

__PACKAGE__->config( namespace => '' );

sub login_url : Private {
    my ( $self, $c ) = @_;

    return $c->uri_for( $self->action_for('login'), { redirect => $c->current_uri_local_part } );
}

sub login : GET HEAD Chained('/base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        title          => "Login",
        username       => $c->req->params->get('username') || $c->session->{username},
        recover_url    => $c->uri_for_action('/user/recover'),
        post_login_url => $c->uri_for(
            $self->action_for('post_login'),
            {
                redirect => $c->forward( _check_redirect_uri => [ $c->req->params->get('redirect') ] ),
            }
        ),
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
        $c->session->{username} = $user->name;

        if ( my $redirect = $c->req->params->get('redirect') ) {
            $c->forward( _check_redirect_uri => [$redirect] );

            $c->redirect_detach( $c->uri_for_local_part($redirect) );
        }

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

sub _check_redirect_uri : Private {
    my ( $self, $c, $uri ) = @_;

    defined $uri
      or return;

    my @regexes = (    # TODO is this sufficient to assert security?
        qr!\.\.!,       # path traversal
        qr!^//!,        # same protocol URI
        qr!^\w+://!,    # explicit protocol URI
    );

    for my $regex (@regexes) {
        $uri =~ $regex
          and $c->detach('/error/bad_request');
    }

    return $uri;
}

sub logout_url : Private {
    my ( $self, $c ) = @_;

    return $c->uri_for( $self->action_for('logout'), { redirect => $c->current_uri_local_part } );
}

sub logout : POST Chained('/base') Args(0) RequiresCapability('logout') {
    my ( $self, $c ) = @_;

    $c->logout();

    if ( my $redirect = $c->req->params->get('redirect') ) {
        $c->forward( _check_redirect_uri => [$redirect] );

        $c->redirect_detach( $c->uri_for_local_part($redirect) );
    }

    $c->response->redirect( $c->uri_for_action('/index') );
}

1;
