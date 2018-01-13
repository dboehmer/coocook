package Coocook::Controller::Error;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

sub forbidden : Private {
    my ( $self, $c ) = @_;

    $c->response->status(403);

    $c->stash(
        title    => "Forbidden",
        template => 'error/forbidden.tt',    # set explicitly to allow $c->detach('/error/forbidden')
    );
}

=head2 not_found

Standard 404 error page

=cut

sub not_found : Chained('/base') PathPart('') {
    my ( $self, $c ) = @_;

    $c->response->status(404);

    $c->stash->{title} = "Not found";
}

__PACKAGE__->meta->make_immutable;

1;
