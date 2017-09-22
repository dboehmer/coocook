package Coocook::Controller::Tag;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

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

    my $groups = $c->project->tag_groups->search(
        undef,
        {
            prefetch => 'tags_sorted',
        },
    );

    $c->stash(
        groups     => [ $groups->all ],
        other_tags => [ $c->project->tags->ungrouped->sorted->all ],
    );
}

sub tag : Chained('/project/base') PathPart('tag') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( tag => $c->project->tags->find($id) );    # TODO error handling
}

sub tag_group : Chained('/project/base') PathPart('tag_group') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( tag_group => $c->project->tag_groups->find($id) );    # TODO error handling
}

sub edit : GET Chained('tag') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( groups => [ $c->project->tag_groups->sorted->all ] );
}

sub delete : POST Chained('tag') Args(0) {
    my ( $self, $c ) = @_;

    my $tag = $c->stash->{tag};
    $tag->deletable or die "Not deletable";
    $tag->delete;
    $c->forward('redirect');
}

sub delete_group : POST Chained('tag_group') PathPart('delete') Args(0) {
    my ( $self, $c ) = @_;

    my $group = $c->stash->{tag_group};
    $group->deletable or die "Not deletable";
    $group->delete;
    $c->forward('redirect');
}

sub create : POST Chained('/project/base') PathPart('tags/create') Args(0) {
    my ( $self, $c ) = @_;

    my $group;    # might be no group
    if ( my $id = scalar $c->req->param('tag_group') ) {
        $group = $c->project->tag_groups->find($id);
    }

    my $tag = $c->project->create_related(
        tags => {
            tag_group => $group,
            name      => scalar $c->req->param('name'),
        }
    );
    $c->forward('redirect');
}

sub create_group : POST Chained('/project/base') PathPart('tag_groups/create') Args(0) {
    my ( $self, $c ) = @_;

    $c->project->create_related(
        tag_groups => {
            name    => scalar $c->req->param('name'),
            comment => scalar $c->req->param('comment'),
        }
    );
    $c->forward('redirect');
}

sub update : POST Chained('tag') Args(0) {
    my ( $self, $c ) = @_;

    my $group;    # might be no group
    if ( my $id = scalar $c->req->param('tag_group') ) {
        $group = $c->project->tag_groups->find($id);
    }

    my $tag = $c->stash->{tag};
    $tag->update(
        {
            name      => scalar $c->req->param('name'),
            tag_group => $group,
        }
    );
    $c->forward( redirect => [$tag] );
}

sub update_group : POST Chained('tag_group') PathPart('update') Args(0) {
    my ( $self, $c, $id ) = @_;

    $c->stash->{tag_group}->update(
        {
            name    => scalar $c->req->param('name'),
            comment => scalar $c->req->param('comment'),
        }
    );
}

sub redirect : Private {
    my ( $self, $c, $tag ) = @_;

    $c->response->redirect(
        $c->project_uri(
            $tag
            ? ( $self->action_for('edit'), $tag->id )
            : ( $self->action_for('index') )
        )
    );
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
