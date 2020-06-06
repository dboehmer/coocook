package Coocook::Controller::Meal;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Meal - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub create : POST Chained('/project/base') PathPart('meals/create') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $meal = $c->project->create_related(
        meals => {
            date    => $c->req->params->get('date'),
            name    => $c->req->params->get('name'),
            comment => $c->req->params->get('comment'),
        }
    );
    $c->detach('redirect');
}

sub base : Chained('/project/base') PathPart('meals') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( meal => $c->project->meals->find($id) || $c->detach('/error/not_found') );
}

sub update : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c, $id ) = @_;

    $c->stash->{meal}->update(
        {
            name    => $c->req->params->get('name'),
            comment => $c->req->params->get('comment'),
        }
    );

    $c->detach('redirect');
}

sub delete : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    if ( $c->stash->{meal}->deletable ) {
        $c->stash->{meal}->delete;
    }
    else {
        my $name = $c->stash->{meal}->name;
        $c->stash->error("$name cannot be deleted, because it contains dishes!");
    }

    $c->detach('redirect');
}

sub delete_dishes : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->stash->{meal}->dishes->update_items_and_delete;

    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->project_uri('/project/edit') );
}

__PACKAGE__->meta->make_immutable;

1;
