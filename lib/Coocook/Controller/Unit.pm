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

    $c->stash(
        units      => $c->model('Schema::Unit'),
        quantities => [ $c->model('Schema::Quantity')->all ],
    );
}

sub create : Local : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Unit')->create(
        {
            short_name          => $c->req->param('short_name'),
            long_name           => $c->req->param('long_name'),
            quantity            => $c->req->param('quantity') || undef,
            to_quantity_default => $c->req->param('to_quantity_default')
              || undef,
        }
    );
    $c->response->redirect( $c->uri_for('/unit') );
}

sub delete : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Unit')->find($id)->delete;
    $c->response->redirect( $c->uri_for('/unit') );
}

sub make_quantity_default : Local Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Unit')->find($id)->make_quantity_default;
    $c->response->redirect( $c->uri_for('/unit') );
}

sub update : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Unit')->find($id)->update(
        {
            short_name => $c->req->param('short_name'),
            long_name  => $c->req->param('long_name'),
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
