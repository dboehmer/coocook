package Coocook::Controller::Error;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

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
