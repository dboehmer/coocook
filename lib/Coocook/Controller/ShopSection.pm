package Coocook::Controller::ShopSection;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::ShopSection - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path('/shop_sections') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( shop_sections => scalar $c->model('Schema::ShopSection') );
}

sub create : Local Args(0) POST {
    my ( $self, $c ) = @_;

    $c->model('Schema::ShopSection')->create(
        {
            name => scalar $c->req->param('name'),
        }
    );

    $c->response->redirect( $c->uri_for_action('/shopsection/index') );
}

sub update : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::ShopSection')->find($id)->update(
        {
            name => scalar $c->req->param('name'),
        }
    );

    $c->response->redirect( $c->uri_for_action('/shopsection/index') );
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
