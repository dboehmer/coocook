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

sub index : GET HEAD Chained('/project/base') PathPart('tags') Args(0)
  RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my $groups = $c->project->tag_groups->search(
        undef,
        {
            prefetch => 'tags_sorted',
        },
    );

    my @groups = $groups->hri->all;

    for my $group (@groups) {
        $group->{update_url} = $c->project_uri( $self->action_for('update_group'), $group->{id} );
        $group->{delete_url} = $c->project_uri( $self->action_for('delete_group'), $group->{id} );
    }

    my @other_tags = $c->project->tags->ungrouped->sorted->hri->all;

    for my $tag (@other_tags) {
        $tag->{edit_url} = $c->project_uri( $self->action_for('edit'), $tag->{id} );
    }

    $c->stash(
        groups               => \@groups,
        other_tags           => \@other_tags,
        create_tag_url       => $c->project_uri( $self->action_for('create') ),
        create_tag_group_url => $c->project_uri( $self->action_for('create_group') ),
        title                => "Tags",
    );
}

sub tag : Chained('/project/base') PathPart('tag') CaptureArgs(1)
  RequiresCapability('view_project') {
    my ( $self, $c, $id ) = @_;

    $c->stash( tag => $c->project->tags->find($id) || $c->detach('/error/not_found') );
}

sub tag_group : Chained('/project/base') PathPart('tag_group') CaptureArgs(1)
  RequiresCapability('view_project') {
    my ( $self, $c, $id ) = @_;

    $c->stash( tag_group => $c->project->tag_groups->find($id) || $c->detach('/error/not_found') );
}

sub edit : GET HEAD Chained('tag') PathPart('') Args(0) RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my $tag = $c->stash->{tag};

    $c->stash( groups => [ $c->project->tag_groups->sorted->all ] );

    my %relationships = (
        articles => '/article/edit',
        dishes   => '/dish/edit',
        recipes  => '/recipe/edit',
    );

    while ( my ( $rel => $path ) = each %relationships ) {
        my @hashrefs = $tag->$rel()->hri->all;    # TODO how to avoid calling the method by name?
                                                  #      the many-to-many rel is not a real relationship

        for my $hashref (@hashrefs) {
            $hashref->{url} = $c->project_uri( $path, $hashref->{id} ),;
        }

        $c->stash( $rel => \@hashrefs );
    }

    $c->stash(
        update_url => $c->project_uri( $self->action_for('update'), $tag->id ),
        delete_url => $tag->deletable ? $c->project_uri( $self->action_for('delete'), $tag->id ) : undef,
    );

    $c->escape_title( Tag => $tag->name );
}

sub delete : POST Chained('tag') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $tag = $c->stash->{tag};
    $tag->deletable or die "Not deletable";
    $tag->delete;
    $c->forward('redirect');
}

sub delete_group : POST Chained('tag_group') PathPart('delete') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $group = $c->stash->{tag_group};
    $group->deletable or die "Not deletable";
    $group->delete;
    $c->forward('redirect');
}

sub create : POST Chained('/project/base') PathPart('tags/create') Args(0)
  RequiresCapability('edit_project') {
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

sub create_group : POST Chained('/project/base') PathPart('tag_groups/create') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->project->create_related(
        tag_groups => {
            name    => $c->req->params->get('name'),
            comment => $c->req->params->get('comment'),
        }
    );
    $c->forward('redirect');
}

sub update : POST Chained('tag') Args(0) RequiresCapability('edit_project') {
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

sub update_group : POST Chained('tag_group') PathPart('update') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c, $id ) = @_;

    $c->stash->{tag_group}->update(
        {
            name    => $c->req->params->get('name'),
            comment => $c->req->params->get('comment'),
        }
    );

    $c->forward('redirect');
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
