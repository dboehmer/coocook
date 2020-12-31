package Coocook::Controller::Project::Tag;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Project::Tag - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub submenu : Chained('/project/base') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        submenu_items => [
            { text => "All tags",       action => 'tag/index' },
            { text => "Add tag",        action => 'tag/new_tag' },
            { text => "All tag groups", action => 'tag/index_tag_group' },
            { text => "Add tag group",  action => 'tag/new_tag_group' },
        ],
    );
}

=head2 index

=cut

sub index : GET HEAD Chained('submenu') PathPart('tags') Args(0)
  RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my $groups = $c->project->tag_groups;

    my @groups = $groups->hri->all;
    my %groups = map { $_->{id} => $_ } @groups;

    for my $group (@groups) {
        $group->{tags} = [];
    }

    my $other_tags = [];

    {
        my $tags = $c->project->tags->sorted->hri;

        while ( my $tag = $tags->next ) {
            $tag->{edit_url} = $c->project_uri( $self->action_for('edit'), $tag->{id} );

            push @{ $tag->{tag_group} ? $groups{ $tag->{tag_group} }{tags} || die : $other_tags }, $tag;
        }
    }

    $c->stash(
        groups     => \@groups,
        other_tags => $other_tags,
    );
}

sub new_tag : GET HEAD Chained('submenu') PathPart('tags/new') Args(0)
  RequiresCapability('view_project') {
    my ( $self, $c, $id ) = @_;

    $c->stash(
        create_url => $c->project_uri( $self->action_for('create') ),
        tag_groups => [ $c->project->tag_groups->sorted->hri->all ],
    );
}

sub index_tag_group : GET HEAD Chained('submenu') PathPart('tag_groups') Args(0)
  RequiresCapability('view_project') {
    my ( $self, $c, $id ) = @_;

    my @groups = $c->project->tag_groups->sorted->hri->all;

    for my $group (@groups) {
        $group->{url} = $c->project_uri( $self->action_for('edit_group'), $group->{id} );
    }

    $c->stash( tag_groups => \@groups );
}

sub new_tag_group : GET HEAD Chained('submenu') PathPart('tag_groups/new') Args(0)
  RequiresCapability('view_project') {
    my ( $self, $c, $id ) = @_;

    $c->stash( create_url => $c->project_uri( $self->action_for('create_group') ) );
}

sub tag : Chained('submenu') PathPart('tag') CaptureArgs(1) RequiresCapability('view_project') {
    my ( $self, $c, $id ) = @_;

    $c->stash( tag => $c->project->tags->find($id) || $c->detach('/error/not_found') );
}

sub tag_group : Chained('submenu') PathPart('tag_group') CaptureArgs(1)
  RequiresCapability('view_project') {
    my ( $self, $c, $id ) = @_;

    $c->stash( tag_group => $c->project->tag_groups->find($id) || $c->detach('/error/not_found') );
}

sub edit : GET HEAD Chained('tag') PathPart('') Args(0) RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my $tag = $c->stash->{tag};

    $c->stash( groups => [ $c->project->tag_groups->sorted->all ] );

    my %relationships = (
        articles => '/project/article/edit',
        dishes   => '/project/dish/edit',
        recipes  => '/project/recipe/edit',
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
}

sub edit_group : GET HEAD Chained('tag_group') PathPart('') Args(0)
  RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my $group = $c->stash->{tag_group};

    my @tags = $group->tags->hri->all;

    for my $tag (@tags) {
        $tag->{url} = $c->project_uri( $self->action_for('edit'), $tag->{id} );
    }

    $c->stash(
        tags       => \@tags,
        update_url => $c->project_uri( $self->action_for('update_group'), $group->id ),
        delete_url => $c->project_uri( $self->action_for('delete_group'), $group->id ),
    );
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
