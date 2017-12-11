package Coocook::Controller::Article;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

Coocook::Controller::Article - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : GET Chained('/project/base') PathPart('articles') Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('fetch_project_data');

    my ( @articles, %articles );

    {
        my $edit_action   = $self->action_for('edit');
        my $delete_action = $self->action_for('delete');

        my %shop_sections = map { $_->id => $_ } @{ $c->stash->{shop_sections} };

        my $articles = $c->project->articles->sorted->inflate_hashes;

        while ( my $article = $articles->next ) {
            $article->{url}        = $c->project_uri( $edit_action,   $article->{id} );
            $article->{delete_url} = $c->project_uri( $delete_action, $article->{id} );
            $article->{units}      = [];
            $article->{shop_section} &&= $shop_sections{ $article->{shop_section} };

            push @articles, $articles{ $article->{id} } = $article;
        }
    }

    # all units of all quantities
    my @units = map { $_->units->all } @{ $c->stash->{quantities} };
    my %units = map { $_->id => $_ } @units;

    my $articles_units = $c->project->articles->articles_units->inflate_hashes;

    while ( my $article_unit = $articles_units->next ) {
        my ( $article => $unit ) = @$article_unit{ 'article', 'unit' };
        push @{ $articles{$article}{units} }, $units{$unit};
    }

    $c->stash(
        articles => \@articles,
        title    => "Articles",
    );
}

sub base : Chained('/project/base') PathPart('article') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( article => $c->project->articles->find($id) );    # TODO error handling
}

sub edit : GET Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('fetch_project_data');

    my $article = $c->stash->{article}
      or die "Can't find article";                               # TODO serious error message

    # collect related recipes linked to dishes and independent dishes
    my $dishes = $article->dishes;
    $dishes = $dishes->search( undef, { order_by => $dishes->me('name'), prefetch => 'meal' } );
    my $recipes = $article->recipes->sorted;

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

    my ( %selected_units, %units_in_use );
    {
        my $units = $article->units;
        $units = $units->search(
            undef,
            {
                'columns'  => ['id'],
                '+columns' => {
                    dish_ingredients_count   => $units->correlate('dish_ingredients')->count_rs->as_query,
                    recipe_ingredients_count => $units->correlate('recipe_ingredients')->count_rs->as_query,
                    items_count              => $units->correlate('items')->count_rs->as_query,
                },
            }
        )->inflate_hashes;

      UNIT: while ( my $unit = $units->next ) {
            $selected_units{ $unit->{id} } = 1;

            for (qw< dish_ingredients_count recipe_ingredients_count items_count >) {
                if ( $unit->{$_} ) {
                    $units_in_use{ $unit->{id} } = 1;
                    next UNIT;
                }
            }
        }
    }

    $c->stash(
        selected_units => \%selected_units,
        units_in_use   => \%units_in_use,
        dishes         => \@dishes,
        recipes        => \@recipes,
    );

    $c->escape_title( Article => $article->name );
}

### CRUD ###

sub create : POST Chained('/project/base') PathPart('articles/create') Args(0) {
    my ( $self, $c, $id ) = @_;

    $c->detach( update_or_insert => [ $c->project->new_related( articles => {} ) ] );
}

sub update : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    $c->detach( update_or_insert => [ $c->stash->{article} ] );
}

sub delete : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{article}->delete();
    $c->detach('redirect');
}

### private helpers ###

sub fetch_project_data : Private {
    my ( $self, $c ) = @_;

    my $quantities = $c->project->quantities;
    $quantities = $quantities->search(
        undef,
        {
            prefetch => 'units',
            order_by => [ $quantities->me('name'), 'units.short_name' ],
        }
    );

    my $shop_sections = $c->project->shop_sections->sorted;

    $c->stash(
        default_shelf_life_days   => 7,
        default_preorder_servings => 10,
        default_preorder_workdays => 3,
        shop_sections             => [ $shop_sections->all ],
        quantities                => [ $quantities->all ],
    );
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->project_uri( $self->action_for('index') ) );
}

sub update_or_insert : Private {
    my ( $self, $c, $article ) = @_;

    my $name = $c->req->param('name');
    if ( $name !~ m/\S/ ) {    # $name contains nothing more than whitespace
        $c->response->redirect(
            $c->project_uri( '/article/edit', $article->id, { error => "Name must not be empty" } ) );
        $c->detach;            # TODO preserve form input
    }

    my $units = $c->project->units->search( { id => { -in => [ $c->req->param('units') ] } } );

    my $tags = $c->project->tags->from_names( scalar $c->req->param('tags') );

    my $shop_section;
    if ( my $id = $c->req->param('shop_section') ) {
        $shop_section = $c->project->shop_sections->find($id);
    }

    $c->txn_do(
        sub {
            if ( scalar $c->req->param('preorder') ) {
                $article->set_columns(
                    {
                        preorder_servings => scalar $c->req->param('preorder_servings'),
                        preorder_workdays => scalar $c->req->param('preorder_workdays'),
                    }
                );
            }
            else {
                $article->set_columns( { preorder_servings => undef, preorder_workdays => undef } );
            }

            $article->set_columns(
                {
                    name         => $name,
                    comment      => scalar $c->req->param('comment'),
                    shop_section => $shop_section ? $shop_section->id : undef,
                    shelf_life_days =>
                      scalar( $c->req->param('shelf_life') ? $c->req->param('shelf_life_days') : undef ),
                }
            );

            $article->update_or_insert;

            # works only after update_or_insert()
            $article->set_tags(  [ $tags->all ] );
            $article->set_units( [ $units->all ] );
        }
    );

    $c->detach('redirect');
}

__PACKAGE__->meta->make_immutable;

1;
