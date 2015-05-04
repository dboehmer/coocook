package Coocook::Controller::Unit;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Unit - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( units => $c->model('Schema::Unit'), );
}

sub create : Local : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Unit')->create( { name => $c->req->param('name') } );
    $c->response->redirect( $c->uri_for('/unit') );
}

sub delete : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Unit')->find($id)->delete;
    $c->response->redirect( $c->uri_for('/unit') );
}

sub update : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Unit')->find($id)->update(
        {
            name => $c->req->param('name'),
        }
    );
    $c->response->redirect( $c->uri_for('/unit') );
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
