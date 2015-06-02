package Coocook::Controller::Tag;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Tag - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path('/tags') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        groups => scalar $c->model('Schema::TagGroup'),
        without_group =>
          scalar $c->model('Schema::Tag')->search( { tag_group => undef } ),
    );
}

sub create : Local Args(0) POST {
    my ( $self, $c ) = @_;
    $c->model('Schema::Tag')->create(
        {
            tag_group => scalar $c->req->param('tag_group'),
            name      => scalar $c->req->param('name'),
        }
    );
    $c->response->redirect( $c->uri_for_action('/tag/index') );
}

sub create_group : Local Args(0) POST {
    my ( $self, $c ) = @_;
    $c->model('Schema::TagGroup')->create(
        {
            name => scalar $c->req->param('name'),
        }
    );
    $c->response->redirect( $c->uri_for_action('/tag/index') );
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
