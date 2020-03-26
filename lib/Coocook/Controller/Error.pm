package Coocook::Controller::Error;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub bad_request : Private {
    my ( $self, $c ) = @_;

    $c->response->status(400);

    $c->stash(
        template => 'error/bad_request.tt',    # set explicitly to allow $c->detach('/error/bad_request')
    );
}

sub forbidden : Private {
    my ( $self, $c, $error ) = @_;

    $error
      and $c->messages->error($error);

    $c->response->status(403);

    $c->stash(
        template => 'error/forbidden.tt',    # set explicitly to allow $c->detach('/error/forbidden')
        method   => $c->req->method,
    );
}

=head2 internal_server_error

An endpoint to receive an HTML page which can be saved and displayed as static 500 error page by a proxy.

=cut

sub internal_server_error : HEAD GET Chained('/base') Public {
    my ( $self, $c ) = @_;

    # do NOT set status to 500 because this actually works

    $c->response->header( 'X-Robots-Tag' => 'noindex' );    # hide this in search engines
}

=head2 not_found

Standard 404 error page

=cut

sub not_found : AnyMethod Chained('/base') PathPart('') Public {
    my ( $self, $c ) = @_;

    $c->response->status(404);

    $c->stash(
        canonical_url => undef,
        template      => 'error/not_found.tt',    # set explicitly to allow $c->detach('/error/not_found')
    );
}

__PACKAGE__->meta->make_immutable;

1;
