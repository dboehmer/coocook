package Coocook::Controller::Quantity;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Quantity - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : GET Chained('/project/base') PathPart('quantities') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( quantities => [ $c->project->quantities->sorted->all ] );
}

sub create : POST Chained('/project/base') PathPart('quantities/create') Args(0) {
    my ( $self, $c ) = @_;

    $c->project->quantities->create( { name => scalar $c->req->param('name') } );
    $c->detach('redirect');
}

sub base : Chained('/project/base') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( quantity => $c->project->quantities->find($id) );    # TODO error handling
}

sub delete : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{quantity}->delete();
    $c->detach('redirect');
}

sub update : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{quantity}->update(
        {
            name => scalar $c->req->param('name'),
        }
    );
    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->project_uri( $self->action_for('index') ) );
}

=encoding utf8

=head1 AUTHOR

Daniel Böhmer,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
