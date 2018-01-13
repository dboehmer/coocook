package Coocook::Controller::Tag;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

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
        title      => "Tags",
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

    $c->escape_title( Tag => $c->stash->{tag}->name );
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
    if ( my $id = $c->req->params->get('tag_group') ) {
        $group = $c->project->tag_groups->find($id);
    }

    my $tag = $c->project->create_related(
        tags => {
            tag_group => $group,
            name      => $c->req->params->get('name'),
        }
    );
    $c->forward('redirect');
}

sub create_group : POST Chained('/project/base') PathPart('tag_groups/create') Args(0) {
    my ( $self, $c ) = @_;

    $c->project->create_related(
        tag_groups => {
            name    => $c->req->params->get('name'),
            comment => $c->req->params->get('comment'),
        }
    );
    $c->forward('redirect');
}

sub update : POST Chained('tag') Args(0) {
    my ( $self, $c ) = @_;

    my $group;    # might be no group
    if ( my $id = $c->req->params->get('tag_group') ) {
        $group = $c->project->tag_groups->find($id);
    }

    my $tag = $c->stash->{tag};
    $tag->update(
        {
            name      => $c->req->params->get('name'),
            tag_group => $group,
        }
    );
    $c->forward( redirect => [$tag] );
}

sub update_group : POST Chained('tag_group') PathPart('update') Args(0) {
    my ( $self, $c, $id ) = @_;

    $c->stash->{tag_group}->update(
        {
            name    => $c->req->params->get('name'),
            comment => $c->req->params->get('comment'),
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

__PACKAGE__->meta->make_immutable;

1;
