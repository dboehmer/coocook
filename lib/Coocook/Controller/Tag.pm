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

sub index : Path('/tags') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        groups     => scalar $c->model('Schema::TagGroup')->sorted,
        other_tags => scalar $c->model('Schema::Tag')->ungrouped->sorted,
    );
}

sub edit : Path Args(1) {
    my ( $self, $c, $id ) = @_;
    $c->stash(
        tag    => $c->model('Schema::Tag')->find($id),
        groups => scalar $c->model('Schema::TagGroup')->sorted,
    );
}

sub delete : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;
    my $tag = $c->model('Schema::Tag')->find($id);
    $tag->deletable or die "Not deletable";
    $tag->delete;
    $c->response->redirect( $c->uri_for_action('/tag/index') );
}

sub delete_group : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;
    my $group = $c->model('Schema::TagGroup')->find($id);
    $group->deletable or die "Not deletable";
    $group->delete;
    $c->response->redirect( $c->uri_for_action('/tag/index') );
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

sub update : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Tag')->find($id)->update(
        {
            name      => scalar $c->req->param('name'),
            tag_group => scalar $c->req->param('tag_group'),
        }
    );
    $c->response->redirect( $c->uri_for_action( '/tag/edit', $id ) );
}

sub update_group : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::TagGroup')->find($id)->update(
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
