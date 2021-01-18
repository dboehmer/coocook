package Coocook::Controller::Article;

use utf8;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Article - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub index : GET HEAD Chained('/project/base') PathPart('articles') Args(0)
  RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    $c->forward('fetch_project_data');

    my ( @articles, %articles );

    {
        my $edit_action   = $self->action_for('edit');
        my $delete_action = $self->action_for('delete');

        my %shop_sections = map { $_->id => $_ } @{ $c->stash->{shop_sections} };

        my $articles = $c->project->articles->sorted->hri;

        # TODO fetch as '+column' with $articles
        my %articles_in_use = map { $_ => 1 } $articles->in_use->get_column('id')->all;

        while ( my $article = $articles->next ) {
            $article->{shop_section_id}
              and $article->{shop_section} = $shop_sections{ $article->{shop_section_id} };

            $article->{units}      = [];
            $article->{edit_url}   = $c->project_uri( $edit_action,   $article->{id} );
            $article->{delete_url} = $c->project_uri( $delete_action, $article->{id} )
              unless $articles_in_use{ $article->{id} };

            push @articles, $articles{ $article->{id} } = $article;
        }
    }

    # all units of all quantities
    my @units = map { $_->units->all } @{ $c->stash->{quantities} };
    my %units = map { $_->id => $_ } @units;

    my $articles_units = $c->project->articles->search_related('articles_units')->hri;

    while ( my $article_unit = $articles_units->next ) {
        my ( $article => $unit ) = @$article_unit{ 'article_id', 'unit_id' };
        push @{ $articles{$article}{units} }, $units{$unit};
    }

    $c->stash(
        articles => \@articles,
        new_url  => $c->project_uri( $self->action_for('new_article') ),
    );
}

sub new_article : GET HEAD Chained('/project/base') PathPart('articles/new')
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->forward('fetch_project_data');

    $c->stash(
        template   => 'article/edit.tt',
        submit_url => $c->project_uri( $self->action_for('create') ),
    );
}

sub base : Chained('/project/base') PathPart('article') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( article => $c->project->articles->find($id) || $c->detach('/error/not_found') );
}

sub edit : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('view_project')
  Does('~HasJS') {
    my ( $self, $c ) = @_;

    my $article = $c->stash->{article};

    $c->forward('fetch_project_data');
    $c->forward('dishes_recipes');

    my $units        = $article->units;
    my $units_in_use = $article->units_in_use;

    $c->stash(
        submit_url     => $c->project_uri( $self->action_for('update'), $article->id ),
        selected_units => { map { $_ => 1 } $units->get_column('id')->all },
        units_in_use   => { map { $_ => 1 } $units_in_use->get_column('id')->all },
    );
}

=head1 CRUD ENDPOINTS

=cut

sub create : POST Chained('/project/base') PathPart('articles/create') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c, $id ) = @_;

    $c->detach( update_or_insert => [ $c->project->new_related( articles => {} ) ] );
}

sub update : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->detach( update_or_insert => [ $c->stash->{article} ] );
}

sub delete : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->forward('dishes_recipes');

    for ( 'dishes', 'recipes' ) {
        if ( @{ $c->stash->{$_} } > 0 ) {
            $c->log->warn( sprintf "article is used in %i %s", scalar @{ $c->stash->{$_} }, $_ );

            $c->detach('/error/bad_request');    # TODO add error text
        }
    }

    $c->stash->{article}->delete();
    $c->detach('redirect');
}

=head1 PRIVATE HELPER METHODS

=head2 fetch_project_data()

=cut

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

=head2 dishes_recipes()

collect related recipes linked to dishes and independent dishes

=cut

sub dishes_recipes : Private {
    my ( $self, $c ) = @_;

    my $article = $c->stash->{article};

    my $dishes = $article->dishes;
    $dishes = $dishes->search( undef, { order_by => $dishes->me('name'), prefetch => 'meal' } );

    my $recipes = $article->recipes->sorted->hri;
    my @recipes = map +{ recipe => $_, dishes => [] }, $recipes->all;    # sorted hashrefs
    my %recipes = map { $_->{recipe}{id} => $_ } @recipes;               # by recipe ID

    for my $r (@recipes) {
        $r->{recipe}{url} = $c->project_uri( '/recipe/edit', $r->{recipe}{id} );
    }

    my @dishes;

    while ( my $dish = $dishes->next ) {
        my $recipe = $dish->from_recipe_id;

        my $meal = $dish->meal;
        $dish         = $dish->as_hashref;
        $dish->{url}  = $c->project_uri( '/dish/edit', $dish->{id} );
        $dish->{meal} = $meal;

        if ( defined $recipe and exists $recipes{$recipe} ) {
            push @{ $recipes{$recipe}{dishes} }, $dish;
        }
        else {
            push @dishes, $dish;
        }
    }

    $c->stash(
        dishes  => \@dishes,
        recipes => \@recipes,
    );
}

sub update_or_insert : Private {
    my ( $self, $c, $article ) = @_;

    my $name = $c->req->params->get('name');

    # $name contains nothing more than whitespace
    # TODO preserve form input
    if ( !defined $name or $name !~ m/\S/ ) {
        $c->messages->error("Name must not be empty");

        $c->redirect_detach( $c->project_uri( '/article/edit', $article->id ) );
    }

    my @tags = $c->project->tags->from_names( $c->req->params->get('tags') )->only_id_col->all;

    my $articles_units = $article->articles_units;

    my @units_in_use = $article->units_in_use->get_column('id')->all;

    my %selected_units = map { $_ => 1 } my @selected_units = $c->req->params->get_all('units');
    my %all_units      = map { $_ => 1 } my @all_units      = $c->project->units->get_column('id')->all;
    my %current_units = map { $_ => 1 } my @current_units = $articles_units->get_column('unit_id')->all;

    for my $sent_id (@selected_units) {
        $all_units{$sent_id}
          or $c->detach( '/error/bad_request', ["Your browser sent an invalid unit ID."] );
    }

    for my $id (@units_in_use) { # this isn't input verification, the HTML form doesn't allow to do this
        $selected_units{$id}
          or $c->detach( '/error/bad_request', ["You’ve deselected a unit that is in use."] );
    }

    my @units_to_remove = grep { not $selected_units{$_} } @current_units;
    my @units_to_add    = grep { not $current_units{$_} } @selected_units;

    my $shop_section;
    if ( my $id = $c->req->params->get('shop_section') ) {
        $shop_section = $c->project->shop_sections->find($id)
          or $c->detach( '/error/bad_request', ["Your browser sent an invalid shop section ID."] );
    }

    $article->txn_do(
        sub {
            if ( $c->req->params->get('preorder') ) {
                $article->set_columns(
                    {
                        preorder_servings => $c->req->params->get('preorder_servings'),
                        preorder_workdays => $c->req->params->get('preorder_workdays'),
                    }
                );
            }
            else {
                $article->set_columns( { preorder_servings => undef, preorder_workdays => undef } );
            }

            $article->set_columns(
                {
                    name            => $name,
                    comment         => $c->req->params->get('comment'),
                    shop_section_id => $shop_section ? $shop_section->id : undef,
                    shelf_life_days => $c->req->params->get('shelf_life')
                    ? $c->req->params->get('shelf_life_days')
                    : undef,
                }
            );

            $article->update_or_insert;

            # works only after update_or_insert()
            $article->set_tags( \@tags );

            # set_units() does a DELETE on all and then re-inserts what violates FK constraints
            # (that's safe for tags because there is no FK constraint on the combination of article & tag)
            @units_to_remove
              and $articles_units->search( { unit_id => { -in => \@units_to_remove } } )->delete();

            # when calling populate() on the related $articles_units resultset, DBIC adds a column 'article'
            @units_to_add
              and $articles_units->result_source->resultset->populate(
                [ [ 'article_id', 'unit_id' ], map { [ $article->id, $_ ] } @units_to_add ] );
        }
    );

    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->project_uri( $self->action_for('index') ) );
}

__PACKAGE__->meta->make_immutable;

1;
