package Coocook::Controller::Meal;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Meal - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub edit : Path : Args(1) {
    my ( $self, $c, $id ) = @_;
    my $meal = $c->model('Schema::Meal')->find($id);
    $c->stash(
        meal    => $meal,
        project => $meal->project,
        recipes => [ $c->model('Schema::Recipe')->all ],
    );
}

sub create : Local Args(0) POST {
    my ( $self, $c ) = @_;
    my $meal = $c->model('Schema::Meal')->create(
        {
            project => scalar $c->req->param('project'),
            date    => scalar $c->req->param('date'),
            name    => scalar $c->req->param('name'),
            comment => scalar $c->req->param('comment'),
        }
    );
    $c->detach( 'redirect', [ $meal->id ] );
}

sub update : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Meal')->find($id)->update(
        {
            name    => scalar $c->req->param('name'),
            comment => scalar $c->req->param('comment'),
        }
    );
    $c->detach( 'redirect', [$id] );
}

sub redirect : Private {
    my ( $self, $c, $id ) = @_;
    $c->response->redirect(
        $c->uri_for_action( $self->action_for('edit'), $id ) );
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
