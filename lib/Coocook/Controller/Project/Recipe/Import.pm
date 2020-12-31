package Coocook::Controller::Recipe::Import;

use Moose;

use MooseX::MarkAsMethods autoclean => 1;
use JSON::MaybeXS ();

BEGIN { extends 'Coocook::Controller' }

sub base : Chained('/project/base') PathPart('recipes/import') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    my $external_recipes =
      $c->model('DB::Recipe')->search( { project => { '!=' => $c->project->id } } );

    my $recipe = $external_recipes->find($id)
      or $c->detach('/error/not_found');

    my $importer = $c->model('RecipeImporter')->new(
        project => $c->project,
        recipe  => $recipe,
    );

    $c->stash(
        importer => $importer,
        recipe   => $recipe,
    );
}

sub preview : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('import_recipe') {
    my ( $self, $c ) = @_;

    my $project = $c->stash->{project};
    my $recipe  = $c->stash->{recipe};

    push @{ $c->stash->{css} }, '/css/recipe/import/preview.css';
    push @{ $c->stash->{js} },  '/js/recipe/import/preview.js';

    my $importer = $c->stash->{importer}->identify_candidates();

    {    # build 'unit_ids_joined' fast
        my $articles = $importer->target_articles;
        my %articles = map { $_->{id} => $_ } @$articles;

        my $articles_units = $project->articles->search_related(
            articles_units => undef,
            { columns => [ 'article_id', 'unit_id' ] }
        );

# see https://metacpan.org/pod/distribution/DBIx-Class/lib/DBIx/Class/Manual/Cookbook.pod#Get-raw-data-for-blindingly-fast-results
        my $cursor = $articles_units->cursor;

        while ( my ( $article => $unit ) = $cursor->next ) {
            push @{ $articles{$article}{unit_ids_joined} }, $unit;
        }

        for my $article (@$articles) {
            $_ = $_ ? join( ',', @$_ ) : '' for $article->{unit_ids_joined};
        }
    }

    my $new_recipe_name       = $recipe->name;
    my @existing_recipe_names = $project->recipes->get_column('name')->all;

    {
        my %existing_recipe_names = map { $_ => undef } @existing_recipe_names;
        my $n                     = 1;

        while ( exists $existing_recipe_names{$new_recipe_name} ) {
            $n++;
            $new_recipe_name =~ s/\d*$/$n/;    # replace any trailing digits with new number
        }
    }

    $c->stash(
        new_recipe_name            => $new_recipe_name,
        existing_recipe_names_json => JSON::MaybeXS->new->encode( \@existing_recipe_names ),
        ingredients                => $importer->ingredients,
        units                      => $importer->target_units,
        articles                   => $importer->target_articles,
        source_project_url         =>
          $c->uri_for_action( '/project/show', [ $recipe->project->id, $recipe->project->url_name ] ),
        import_url => $c->project_uri( $self->action_for('post'), $recipe->id ),
        recipe_url => $c->uri_for_action( '/browse/recipe/show', [ $recipe->id, $recipe->url_name ] ),
    );
}

sub post : POST Chained('base') PathPart('') Args(0) RequiresCapability('import_recipe') {
    my ( $self, $c ) = @_;

    # This doesn't preserve form inputs
    #   but the error condition is already checked by JavaScript.
    # This only prevents internal server errors from the SQL error
    #   when going back in browser history and sending the form again.
    if ( $c->project->recipes->results_exist( { name => $c->req->params->get('name') } ) ) {
        $c->messages->error("A recipe with that name does already exist");
        $c->stash( template => 'recipe/import/preview.tt' );
        $c->detach('preview');
    }

    my $importer = $c->stash->{importer};

    my %ingredients;

    for my $ingredient ( @{ $importer->ingredients } ) {
        my $id = $ingredient->{id};

        $ingredients{$id} =
          ( $c->req->params->get("import$id") // '' ) eq 'on'
          ? {
            value   => $c->req->params->get("value$id"),
            unit    => $c->req->params->get("unit$id"),
            article => $c->req->params->get("article$id"),
            comment => $c->req->params->get("comment$id"),
          }
          : { skip => 1 };
    }

    my $new_recipe = $importer->import_data(
        name        => $c->req->params->get('name'),
        servings    => $c->req->params->get('servings'),
        ingredients => \%ingredients,
    );

    $c->redirect_detach( $c->project_uri( '/recipe/edit', $new_recipe->id ) );
}

1;
