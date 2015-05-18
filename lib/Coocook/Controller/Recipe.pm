package Coocook::Controller::Recipe;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Recipe - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( recipes => $c->model('Schema::Recipe'), );
}

sub edit : Local : Args(1) {
    my ( $self, $c, $id ) = @_;
    $c->stash( recipe => $c->model('Schema::Recipe')->find($id) );
}

sub create : Local : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Recipe')->create( { 
name => $c->req->param('name'),
description => $c->req->param('description') // "",
 } );
    $c->response->redirect( $c->uri_for_action( $self->action_for('edit')), $id );
}

sub delete : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Recipe')->find($id)->delete;
    $c->response->redirect( $c->uri_for_action('/recipe/index') );
}

sub update : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Recipe')->find($id)->update(
        {
            name => $c->req->param('name'),
	description => $c->req->param('description'),
        }
    );
    $c->response->redirect( $c->uri_for_action('/recipe/edit', $id) );
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
