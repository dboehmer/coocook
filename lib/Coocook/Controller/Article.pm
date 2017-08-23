package Coocook::Controller::Article;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Article - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->stash(
        default_shelf_life_days   => 7,
        default_preorder_servings => 10,
        default_preorder_workdays => 3,
    );

    my $quantities = $c->model('DB::Quantity');
    $quantities = $quantities->search(
        undef,
        {
            prefetch => 'units',
            order_by => [ $quantities->me('name'), 'units.short_name', ],
        }
    );

    $c->stash(
        shop_sections => [ $c->model('DB::ShopSection')->sorted->all ],
        quantities    => [ $quantities->all ],
    );
}

sub index : GET Chained('/project/base') PathPath('articles') Args(0) {
    my ( $self, $c ) = @_;

    my $articles = $c->stash->{project}->articles;

    $c->stash( articles => $articles );
}

sub edit : GET Chained('/project/base') PathPart('article') Args(1) {
    my ( $self, $c, $id ) = @_;

    my $article = $c->model('DB::Article')->find($id)
      or die "Can't find article";    # TODO serious error message

    # collect related recipes linked to dishes and independent dishes
    my $dishes = $article->dishes;
    $dishes = $dishes->search( undef, { order_by => $dishes->me('name'), prefetch => 'meal' } );
    my $recipes = $article->recipes->search( undef, { order_by => 'name' } );

    my @dishes;
    my @recipes = map +{ recipe => $_, dishes => [] }, $recipes->all;    # sorted hashrefs
    my %recipes = map { $$_{recipe}->id => $_ } @recipes;                # by ID

    while ( my $dish = $dishes->next ) {
        my $recipe = $dish->from_recipe;

        if ( defined $recipe and exists $recipes{$recipe} ) {
            push @{ $recipes{$recipe}{dishes} }, $dish;
        }
        else {
            push @dishes, $dish;
        }
    }

    $c->stash(
        article => $article,
        dishes  => \@dishes,
        recipes => \@recipes,
    );
}

sub create : POST Chained('/project/base') PathPart('articles/create') Args(0) {
    my ( $self, $c, $id ) = @_;

    my $units = $c->model('DB::Unit')->search(
        {
            id => { -in => [ $c->req->param('units') ] },
        }
    );

    my $tags =
      $c->model('DB::Tag')->from_names( scalar $c->req->param('tags') );

    my $shelf_life_days = undef;

    if ( $c->req->param('shelf_life') and defined( my $days = $c->req->param('shelf_life_days') ) ) {
        $shelf_life_days = $days;
    }

    my ( $preorder_servings, $preorder_workdays );

    if ( $c->req->param('preorder') ) {
        $preorder_servings = $c->req->param('preorder_servings');
        $preorder_workdays = $c->req->param('preorder_workdays');
    }

    $c->model('DB')->schema->txn_do(
        sub {
            my $article = $c->model('DB::Article')->create(
                {
                    name              => scalar $c->req->param('name'),
                    comment           => scalar $c->req->param('comment'),
                    shop_section      => scalar $c->req->param('shop_section'),
                    shelf_life_days   => $shelf_life_days,
                    preorder_servings => $preorder_servings,
                    preorder_workdays => $preorder_workdays,
                }
            );

            $article->set_tags(  [ $tags->all ] );
            $article->set_units( [ $units->all ] );
        }
    );
    $c->detach('redirect');
}

sub delete : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('DB::Article')->find($id)->delete;
    $c->detach('redirect');
}

sub update : POST Path Args(1) {
    my ( $self, $c, $id ) = @_;

    my $units = $c->model('DB::Unit')->search(
        {
            id => { -in => [ $c->req->param('units') ] },
        }
    );

    my $tags =
      $c->model('DB::Tag')->from_names( scalar $c->req->param('tags') );

    my $article = $c->model('DB::Article')->find($id);

    $c->model('DB')->schema->txn_do(
        sub {
            $article->set_tags(  [ $tags->all ] );
            $article->set_units( [ $units->all ] );
            $article->set_columns(
                {
                    name         => scalar $c->req->param('name'),
                    comment      => scalar $c->req->param('comment'),
                    shop_section => scalar $c->req->param('shop_section'),
                }
            );
            if ( scalar $c->req->param('shelf_life') ) {
                $article->set_columns(
                    {
                        shelf_life_days => scalar $c->req->param('shelf_life_days')
                    }
                );
            }
            else {
                $article->set_columns( { shelf_life_days => undef } );
            }
            if ( scalar $c->req->param('preorder') ) {
                $article->set_columns(
                    {
                        preorder_servings => scalar $c->req->param('preorder_servings'),
                        preorder_workdays => scalar $c->req->param('preorder_workdays'),
                    }
                );
            }
            else {
                $article->set_columns( { preorder_servings => undef, preorder_workdays => undef, } );
            }
            $article->update;
        }
    );

    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->uri_for_action( $self->action_for('index') ) );
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
