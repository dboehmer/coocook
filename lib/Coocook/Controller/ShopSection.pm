package Coocook::Controller::ShopSection;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => 'shop_section' );

=head1 NAME

Coocook::Controller::ShopSection - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : GET Chained('/project/base') PathPart('shop_sections') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        shop_sections => [ $c->project->shop_sections->with_article_count->sorted->all ],
        title         => "Shop sections",
    );
}

sub create : POST Chained('/project/base') PathPart('shop_sections/create') Args(0) {
    my ( $self, $c ) = @_;

    $c->project->create_related(
        shop_sections => {
            name => $c->req->params->get('name'),
        }
    );

    $c->detach('redirect');
}

sub base : Chained('/project/base') PathPart('shop_sections') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( shop_section => $c->project->shop_sections->find($id) );
}

sub update : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{shop_section}->update(
        {
            name => $c->req->params->get('name'),
        }
    );

    $c->detach('redirect');
}

sub delete : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{shop_section}->delete;
    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->project_uri( $self->action_for('index') ) );
}

__PACKAGE__->meta->make_immutable;

1;
