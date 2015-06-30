package Coocook::Controller::Dish;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Dish - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub edit : Path Args(1) {
    my ( $self, $c, $id ) = @_;

    my $dish = $c->model('Schema::Dish')->find($id);

    $c->stash(
        dish     => $dish,
        articles => [ $c->model('Schema::Article')->all ],
        units    => [ $c->model('Schema::Unit')->all ],

    );
}

sub delete : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;

    my $dish = $c->model('Schema::Dish')->find($id);

    $dish->delete;

    $c->response->redirect(
        $c->uri_for_action( '/meal/edit', $dish->get_column('meal') ) );
}

sub from_recipe : Local Args(0) POST {
    my ( $self, $c ) = @_;

    my $meal = $c->model('Schema::Meal')->find( scalar $c->req->param('meal') );
    my $recipe =
      $c->model('Schema::Recipe')->find( scalar $c->req->param('recipe') );

    $c->model('Schema::Dish')->from_recipe(
        $recipe,
        (
            meal     => $meal->id,
            servings => scalar $c->req->param('servings'),
            comment  => scalar $c->req->param('comment'),
        )
    );

    $c->response->redirect( $c->uri_for_action( '/meal/edit', $meal->id ) );
}

sub recalculate : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;

    my $dish = $c->model('Schema::Dish')->find($id);

    $dish->recalculate( scalar $c->req->param('servings') );

    $c->response->redirect(
        $c->uri_for_action( '/meal/edit', $dish->get_column('meal') ) );
}

sub update : Local Args(1) POST {

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
