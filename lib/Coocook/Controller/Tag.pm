package Coocook::Controller::Tag;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Tag - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : GET Chained('/project/base') PathPart('tags') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        groups     => $c->model('DB::TagGroup')->sorted,
        other_tags => $c->model('DB::Tag')->ungrouped->sorted,
    );
}

sub edit : GET Chained('/project/base') PathPart('tag') Args(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash(
        tag    => $c->model('DB::Tag')->find($id),
        groups => $c->model('DB::TagGroup')->sorted,
    );
}

sub delete : POST Chained('/project/base') PathPart('tag/delete') Args(1) {
    my ( $self, $c, $id ) = @_;

    my $tag = $c->model('DB::Tag')->find($id);
    $tag->deletable or die "Not deletable";
    $tag->delete;
    $c->response->redirect( $c->uri_for_action('/tag/index') );
}

sub delete_group : POST Chained('/project/base') PathPart('tag_group/delete') Args(1) {
    my ( $self, $c, $id ) = @_;

    my $group = $c->model('DB::TagGroup')->find($id);
    $group->deletable or die "Not deletable";
    $group->delete;
    $c->response->redirect( $c->uri_for_action('/tag/index') );
}

sub create : POST Chained('/project/base') PathPart('tag/create') Args(0) {
    my ( $self, $c ) = @_;

    $c->model('DB::Tag')->create(
        {
            tag_group => scalar $c->req->param('tag_group'),
            name      => scalar $c->req->param('name'),
        }
    );
    $c->response->redirect( $c->uri_for_action('/tag/index') );
}

sub create_group : POST Chained('/project/base') PathPart('tag_group/create') Args(0) {
    my ( $self, $c ) = @_;

    $c->model('DB::TagGroup')->create(
        {
            name    => scalar $c->req->param('name'),
            comment => scalar $c->req->param('comment'),
        }
    );
    $c->response->redirect( $c->uri_for_action('/tag/index') );
}

sub update : POST Chained('/project/base') PathPart('tag/update') Args(1) {
    my ( $self, $c, $id ) = @_;

    $c->model('DB::Tag')->find($id)->update(
        {
            name      => scalar $c->req->param('name'),
            tag_group => scalar $c->req->param('tag_group'),
        }
    );
    $c->response->redirect( $c->uri_for_action( '/tag/edit', $id ) );
}

sub update_group : POST Chained('/project/base') PathPart('tag_group/update') Args(1) {
    my ( $self, $c, $id ) = @_;
    $c->model('DB::TagGroup')->find($id)->update(
        {
            name    => scalar $c->req->param('name'),
            comment => scalar $c->req->param('comment'),
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
