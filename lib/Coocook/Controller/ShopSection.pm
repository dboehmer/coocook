package Coocook::Controller::ShopSection;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config( namespace => 'shop_section' );

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

    $c->stash( shop_sections => $c->model('Schema::ShopSection')->with_article_count->sorted );
}

sub create : Local Args(0) POST {
    my ( $self, $c ) = @_;

    $c->model('Schema::ShopSection')->create(
        {
            name => scalar $c->req->param('name'),
        }
    );

    $c->detach('redirect');
}

sub update : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;

    $c->model('Schema::ShopSection')->find($id)->update(
        {
            name => scalar $c->req->param('name'),
        }
    );

    $c->detach('redirect');
}

sub delete : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;

    $c->model('Schema::ShopSection')->find($id)->delete;
    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->uri_for_action( $self->action_for('index') ) );
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
