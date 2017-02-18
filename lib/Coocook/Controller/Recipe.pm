package Coocook::Controller::Recipe;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use Scalar::Util qw(looks_like_number);

# Chrissi sperrt ihren Bildschirm nicht!!!!11111

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

    $c->stash( recipes => $c->model('Schema::Recipe')->sorted_rs );
}

sub edit : Path : Args(1) {
    my ( $self, $c, $id ) = @_;

    my $recipe = $c->model('Schema::Recipe')->find($id);

    my $ingredients = $recipe->ingredients;
    $ingredients = $ingredients->search(
        undef,
        {
            prefetch => [qw< article unit >],
            order_by => $ingredients->me('position'),
        }
    );

    $c->stash(
        recipe      => $recipe,
        ingredients => [ $ingredients->all ],
        articles    => [ $c->model('Schema::Article')->sorted ],
        units       => [ $c->model('Schema::Unit')->sorted ],
    );
}

sub add : Local : Args(1) {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::RecipeIngredient')->create(
        {
            recipe  => $id,
            prepare => ($c->req->param('prepare') ? 1 : 0),
            article => scalar $c->req->param('article'),
            value   => scalar $c->req->param('value'),
            unit    => scalar $c->req->param('unit'),
            comment => scalar $c->req->param('comment'),
        }
    );
    $c->detach( 'redirect', [$id] );
}

sub create : Local : POST {
    my ( $self, $c ) = @_;
    my $name = scalar $c->req->param('name');
    my $input_okay = my $input_okay = $self->check_name($c, {name => $name, current_page => "/recipes"});
    if ($input_okay){
        my $recipe = $c->model('Schema::Recipe')->create(
        {
            name        => $name,
            description => scalar $c->req->param('description') // "",
            preparation => scalar $c->req->param('preparation') // "",
            servings    => scalar $c->req->param('servings'),
        }
    );
    $c->detach( 'redirect', [ $recipe->id ] );
    }
    
}

sub duplicate : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;

    $c->model('Schema::Recipe')->find($id)
      ->duplicate( { name => scalar $c->req->param('name') } );

    $c->detach( 'redirect', [] );
}

sub delete : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Recipe')->find($id)->delete;
    $c->detach( 'redirect', [] );
}

sub update : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    my $recipe = $c->model('Schema::Recipe')->find($id);
    my $name = scalar $c->req->param('name');
    my $input_okay = $self->check_name($c, {name => $name, current_page => "/recipe/$id"});
    if($input_okay){
        $c->model('Schema')->schema->txn_do(
        sub {
            $recipe->update(
                {
                    name        => $name,
                    preparation => scalar $c->req->param('preparation'),
                    description => scalar $c->req->param('description'),
                    servings    => scalar $c->req->param('servings'),
                }
            );

            # ingredients
            for my $ingredient ( $recipe->ingredients ) {
                if ( scalar $c->req->param( 'delete' . $ingredient->id ) ) {
                    $ingredient->delete;
                    next;
                }

                $ingredient->update(
                    {
                        prepare => ( $c->req->param( 'prepare' . $ingredient->id ) ? 1 : 0 ),
                        value   => scalar $c->req->param( 'value' . $ingredient->id ),
                        unit    => scalar $c->req->param( 'unit' . $ingredient->id ),
                        comment => scalar $c->req->param( 'comment' . $ingredient->id ),
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
    
}

sub reposition : POST Local Args(1) {
    my ( $self, $c, $id ) = @_;

    my $ingredient = $c->model('Schema::RecipeIngredient')->find($id);

    if ( $c->req->param('up') ) {
        $ingredient->move_previous();
    }
    elsif ( $c->req->param('down') ) {
        $ingredient->move_next();
    }
    else {
        die "No valid movement";
    }

    $c->detach( redirect => [ $ingredient->get_column('recipe'), '#ingredients' ] );
}

sub redirect : Private {
    my ( $self, $c, $id, $fragment ) = @_;

    if ($id) {
        $c->response->redirect(
            $c->uri_for_action( $self->action_for('edit'), $id ) . ( $fragment // '' ) );
    }
    else {
        $c->response->redirect(
            $c->uri_for_action( $self->action_for('index') ) );
    }
}

sub check_name : Private {
    my ( $self, $c, $args) = @_;
    my $name = $args->{name};
    $c->log->info("name$name");
    my $current_page = $args->{current_page};
    my $result = 1;
    if (length($name) <= 0){
		$c->response->redirect(
                $c->uri_for( $current_page, { error => "Cannot create recipe with empty name!" } ) );
        $result = 0;
    }
    return $result;
}

sub check_value : Private {
    my ( $self, $c, ) = @_;
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
