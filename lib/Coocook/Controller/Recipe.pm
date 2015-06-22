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

sub index : Path('/recipes') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( recipes => $c->model('Schema::Recipe'), );
}

sub edit : Path : Args(1) {
    my ( $self, $c, $id ) = @_;
    my $recipe = $c->model('Schema::Recipe')->find($id);
    $c->stash(
        recipe      => $recipe,
        ingredients => [ $recipe->ingredients->all ],
        articles    => [ $c->model('Schema::Article')->all ],
        units       => [ $c->model('Schema::Unit')->all ],
    );
}

sub add : Local : Args(1) {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::RecipeIngredient')->create(
        {
            recipe  => $id,
            article => $c->req->param('article'),
            value   => $c->req->param('value'),
            unit    => $c->req->param('unit'),
            comment => $c->req->param('comment'),
        }
    );
    $c->detach( 'redirect', [$id] );
}

sub create : Local : POST {
    my ( $self, $c ) = @_;
    my $recipe = $c->model('Schema::Recipe')->create(
        {
            name        => $c->req->param('name'),
            description => $c->req->param('description') // "",
            preparation => $c->req->param('preparation') // "",
            servings    => $c->req->param('servings'),
        }
    );
    $c->detach( 'redirect', [ $recipe->id ] );
}

sub delete : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Recipe')->find($id)->delete;
    $c->detach( 'redirect', [] );
}

sub update : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    my $recipe = $c->model('Schema::Recipe')->find($id);

    $c->model('Schema')->schema->txn_do(
        sub {
            $recipe->update(
                {
                    name        => $c->req->param('name'),
                    description => $c->req->param('description'),
                    servings    => $c->req->param('servings'),
                }
            );

            # ingredients
            for my $ingredient ( $recipe->ingredients ) {
                if ( $c->req->param( 'delete' . $ingredient->id ) ) {
                    $ingredient->delete;
                    next;
                }

                $ingredient->update(
                    {
                        value => $c->req->param( 'value' . $ingredient->id ),
                        unit  => $c->req->param( 'unit' . $ingredient->id ),
                        comment =>
                          $c->req->param( 'comment' . $ingredient->id ),
                    }
                );
            }

            # tags
            my $tags = $c->model('Schema::Tag')
              ->from_names( scalar $c->req->param('tags') );
            $recipe->set_tags( [ $tags->all ] );
        }
    );

    $c->detach( 'redirect', [$id] );
}

sub redirect : Private {
    my ( $self, $c, $id ) = @_;
    if ($id) {
        $c->response->redirect(
            $c->uri_for_action( $self->action_for('edit'), $id ) );
    }
    else {
        $c->response->redirect(
            $c->uri_for_action( $self->action_for('index') ) );
    }
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
