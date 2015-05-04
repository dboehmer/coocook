package Coocook::Controller::Recipe;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Recipe - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( recipes => $c->model('Schema::Recipe'), );
}

sub edit : Local : Args(1) {
    my ( $self, $c, $id ) = @_;
    my $recipe = $c->model('Schema::Recipe')->find($id);
    $c->stash(
        recipe      => $recipe,
        ingredients => [ $recipe->ingredients->all ],
        products    => [ $c->model('Schema::Product')->all ],
        units       => [ $c->model('Schema::Unit')->all ],
    );
}

sub add : Local : Args(1) {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Ingredient')->create(
        {
            recipe   => $id,
            product  => $c->req->param('product'),
            quantity => $c->req->param('quantity'),
            unit     => $c->req->param('unit'),
        }
    );
    $c->response->redirect(
        $c->uri_for_action( $self->action_for('edit'), $id ) );
}

sub create : Local : POST {
    my ( $self, $c ) = @_;
    my $recipe = $c->model('Schema::Recipe')->create(
        {
            name        => $c->req->param('name'),
            description => $c->req->param('description') // "",
            servings    => $c->req->param('servings'),
        }
    );
    $c->response->redirect(
        $c->uri_for_action( $self->action_for('edit'), $recipe->id ) );
}

sub delete : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Recipe')->find($id)->delete;
    $c->response->redirect( $c->uri_for_action('/recipe/index') );
}

sub update : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Recipe')->find($id)->update(
        {
            name        => $c->req->param('name'),
            description => $c->req->param('description'),
            servings    => $c->req->param('servings'),
        }
    );
    $c->response->redirect( $c->uri_for_action( '/recipe/edit', $id ) );
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
