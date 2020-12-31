package Coocook::Controller::ShopSection;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

__PACKAGE__->config( namespace => 'shop_section' );

=head1 NAME

Coocook::Controller::ShopSection - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : GET HEAD Chained('/purchase_list/submenu') PathPart('shop_sections') Args(0)
  RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my @shop_sections = $c->project->shop_sections->with_article_count->sorted->hri->all;

    for my $section (@shop_sections) {
        $section->{update_url} = $c->project_uri( $self->action_for('update'), $section->{id} );

        $section->{delete_url} = $c->project_uri( $self->action_for('delete'), $section->{id} )
          unless $section->{article_count} > 0;
    }

    $c->stash(
        shop_sections => \@shop_sections,
        create_url    => $c->project_uri( $self->action_for('create') ),
    );
}

sub create : POST Chained('/project/base') PathPart('shop_sections/create') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $name     = $c->req->params->get('name');
    my $sections = $c->project->search_related('shop_sections');

    if ( $sections->search( { name => $name } )->results_exist ) {
        $c->messages->error("A shop section with that name already exists!");

        $c->stash( last_input => { name => $name } );

        $c->go( 'index', [ $c->project->id, $c->project->url_name ], [] );
    }

    $sections->create(
        {
            name => $c->req->params->get('name'),
        }
    );

    $c->detach('redirect');
}

sub base : Chained('/project/base') PathPart('shop_sections') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( shop_section => $c->project->shop_sections->find($id)
          || $c->detach('/error/not_found') );
}

sub update : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->stash->{shop_section}->update(
        {
            name => $c->req->params->get('name') // $c->forward('/error/bad_request'),
        }
    );

    $c->detach('redirect');
}

sub delete : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->stash->{shop_section}->deletable
      or $c->detach('/error/bad_request');

    $c->stash->{shop_section}->delete;

    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->project_uri( $self->action_for('index') ) );
}

__PACKAGE__->meta->make_immutable;

1;
