package Coocook::Controller::Meal;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

Coocook::Controller::Meal - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub create : POST Chained('/project/base') PathPart('meals/create') Args(0) {
    my ( $self, $c ) = @_;

    my $meal = $c->project->create_related(
        meals => {
            date    => scalar $c->req->param('date'),
            name    => scalar $c->req->param('name'),
            comment => scalar $c->req->param('comment'),
        }
    );
    $c->detach('redirect');
}

sub base : Chained('/project/base') PathPart('meals') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( meal => $c->project->meals->find($id) );    # TODO error handling
}

sub update : POST Chained('base') Args(0) {
    my ( $self, $c, $id ) = @_;

    $c->stash->{meal}->update(
        {
            name    => scalar $c->req->param('name'),
            comment => scalar $c->req->param('comment'),
        }
    );

    $c->detach('redirect');
}

sub delete : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{meal}->delete();
    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->project_uri('/project/edit') );
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
