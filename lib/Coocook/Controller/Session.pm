package Coocook::Controller::Session;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub login : GET HEAD Chained('/base') Args(0) Public {
    my ( $self, $c ) = @_;

    if ( $c->user ) {    # user is already logged in, probably via other browser tab
        $c->detach('/_validated_redirect');
    }

    $c->stash(
        username => (
                 $c->req->params->get('username')
              || $c->session->{username}    # session is more trustworthy than plaintext cookie
              || map { $_ ? $_->value : undef } $c->req->cookie('username')
        ),
        recover_url    => $c->uri_for_action('/user/recover'),
        post_login_url => $c->redirect_uri_for_action( $self->action_for('post_login') ),
    );
}

sub post_login : POST Chained('/base') PathPart('login') Args(0) Public {
    my ( $self, $c ) = @_;

    # slow down brute-force-attacks by sleeping for a while
    # before even analyzing the request
    # ALWAYS SLEEP EVEN IF CREDENTIALS ARE CORRECT!
    # Otherwise a client can assume failure if the request
    # is not answered in 0.x seconds ...
    sleep 1;

    my $user = $c->authenticate(
        {
            name           => $c->req->body_params->get('username'),
            password_hash  => $c->req->body_params->get('password'),
            email_verified => { '!=' => undef },
        }
    );

    if ($user) {
        $c->session->{username} = $user->name;

        $c->res->cookies->{username} = {
            value    => $user->name,
            expires  => '+12M',        # in 12 months (syntax supported by CGI::Simple)
            path     => '/login',
            secure   => 1,             # only via HTTPS
            httponly => 1,             # not accessible by client-side JavaScript
        };

        $c->detach('/_validated_redirect');
    }

    $c->logout();

    $c->response->redirect(
        $c->redirect_uri_for_action(
            $self->action_for('login'),
            {
                error    => "Sign in failed!",
                username => $c->req->params->get('username'),
            }
        )
    );
}

sub logout : POST Chained('/base') Args(0) RequiresCapability('logout') {
    my ( $self, $c ) = @_;

    $c->logout();

    $c->detach('/_validated_redirect');
}

1;
