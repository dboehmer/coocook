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

sub index : GET Chained('/project/base') PathPart('recipes') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( recipes => $c->project->recipes->sorted );
}

sub base : Chained('/project/base') PathPart('recipe') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( recipe => $c->project->recipes->find($id) );    # TODO error handling
}

sub edit : GET Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $recipe = $c->stash->{recipe};

    my @articles = $c->project->articles->sorted->all;
    my @units    = $c->project->units->sorted->all;

    my %articles = map { $_->id => $_ } @articles;
    my %units    = map { $_->id => $_ } @units;

    my @ingredients;
    {
        my $ingredients = $recipe->ingredients;
        $ingredients = $ingredients->search( undef, { order_by => $ingredients->me('position') } );

        while ( my $ingredient = $ingredients->next ) {
            push @ingredients,
              {
                id             => $ingredient->id,
                prepare        => $ingredient->prepare,
                value          => $ingredient->value,
                unit           => $units{ $ingredient->get_column('unit') },
                article        => $articles{ $ingredient->get_column('article') },
                comment        => $ingredient->comment,
                reposition_url => $c->project_uri( '/recipe/reposition', $ingredient->id ),
              };
        }
    }

    my @dishes;
    {
        my $dishes = $recipe->dishes->search(
            undef,
            {
                prefetch => 'meal',
                order_by => 'meal.date',
            }
        );

        while ( my $dish = $dishes->next ) {
            push @dishes,
              {
                name => $dish->name,
                meal => $dish->meal->name,
                date => $dish->meal->date,
                url  => $c->project_uri( '/dish/edit', $dish->id ),
              };
        }
    }

    $c->stash(
        recipe             => $recipe,
        articles           => \@articles,
        units              => \@units,
        ingredients        => \@ingredients,
        dishes             => \@dishes,
        add_ingredient_url => $c->project_uri( '/recipe/add', $recipe->id ),
    );
}

sub add : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $recipe = $c->stash->{recipe};

    $recipe->create_related(
        ingredients => {
            prepare => ( $c->req->param('prepare') ? 1 : 0 ),
            article => scalar $c->req->param('article'),
            value   => scalar $c->req->param('value'),
            unit    => scalar $c->req->param('unit'),
            comment => scalar $c->req->param('comment'),
        }
    );

    $c->detach( redirect => [ $recipe->id, '#ingredients' ] );
}

sub create : POST Chained('/project/base') Args(0) {
    my ( $self, $c ) = @_;

    my $name = scalar $c->req->param('name');
    my $input_okay = $self->check_name( $c, { name => $name, current_page => "/recipes" } );
    if ($input_okay) {
        my $recipe = $c->project->create_related(
            recipes => {
                name        => $name,
                description => scalar $c->req->param('description') // "",
                preparation => scalar $c->req->param('preparation') // "",
                servings    => scalar $c->req->param('servings'),
            }
        );
        $c->detach( redirect => [ $recipe->id ] );
    }

}

sub duplicate : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $recipe = $c->stash->{recipe}->duplicate( { name => scalar $c->req->param('name') } );

    $c->detach( redirect => [ $recipe->id ] );
}

sub delete : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $recipe = $c->stash->{recipe}->delete;
    $c->detach('redirect');
}

sub update : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $recipe = $c->stash->{recipe};
    my $name   = scalar $c->req->param('name');
    my $input_okay =
      $self->check_name( $c, { name => $name, current_page => "/recipe/" . $recipe->id } );
    if ($input_okay) {
        $c->model('DB')->schema->txn_do(
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
                for my $ingredient ( $recipe->ingredients->all ) {
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
                my $tags = $c->model('DB::Tag')->from_names( scalar $c->req->param('tags') );
                $recipe->set_tags( [ $tags->all ] );
            }
        );

        $c->detach( 'redirect', [ $recipe->id ] );    # no fragment here, could be text edit

    }

}

sub reposition : POST Chained('/project/base') PathPart('recipe_ingredient/reposition') Args(1) {
    my ( $self, $c, $id ) = @_;

    my $ingredient = $c->project->recipes->ingredients->find($id);

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
    my ( $self, $c, $recipe, $fragment ) = @_;

    if ($recipe) {
        $c->response->redirect(
            $c->project_uri( $self->action_for('edit'), ref $recipe ? $recipe->id : $recipe )
              . ( $fragment // '' ) );
    }
    else {
        $c->response->redirect( $c->project_uri( $self->action_for('index') ) );
    }
}

sub check_name : Private {
    my ( $self, $c, $args ) = @_;
    my $name = $args->{name};
    $c->log->info("name$name");
    my $current_page = $args->{current_page};
    my $result       = 1;
    if ( length($name) <= 0 ) {
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
