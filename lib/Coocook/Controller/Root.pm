package Coocook::Controller::Root;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

=encoding utf-8

=head1 NAME

Coocook::Controller::Root - Root Controller for Coocook

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub begin : Private {
    my ( $self, $c ) = @_;

    if ( my $id = $c->session->{project} ) {
        $c->stash( my_project => $c->model('Schema::Project')->find($id) );
    }
    else {
        $c->response->redirect( $c->uri_for_action('/project/index') );
    }
}

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->stash(
        css => ['style.css'],
        js  => ['script.js'],
    );
}

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
}

=head2 default

Standard 404 error page

=cut

sub default : Path {
    my ( $self, $c ) = @_;
    $c->response->body('Page not found');
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') { }

=head1 AUTHOR

Daniel Böhmer,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
