package Coocook::Controller::API;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

# BEGIN-block necessary to make method attributes work
BEGIN { extends 'Coocook::Controller' }

sub base : Chained('/') PathPart('api') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash( current_view => 'JSON' );
}

sub statistics : GET HEAD Chained('base') Args(0) Public {
    my ( $self, $c ) = @_;

    $c->stash( json_data => $c->model('DB')->statistics );
}

sub end : ActionClass('RenderView') { }    # Overrides Controller::Root->end

__PACKAGE__->meta->make_immutable;

1;
