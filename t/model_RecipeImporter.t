use Test2::V0;

use Coocook::Model::RecipeImporter;
use Coocook::Model::ProjectImporter;

use lib 't/lib/';
use TestDB;

plan(32);

my $schema = TestDB->new();

my $source_project = $schema->resultset('Project')->find(1);
my $source_recipe  = $schema->resultset('Recipe')->find(1);

my $target_project = $schema->resultset('Project')->create(
    {
        name        => "target project",
        description => __FILE__,
        owner_id    => 1
    }
);

ok my $importer = Coocook::Model::RecipeImporter->new(
    project => $target_project,
    recipe  => $source_recipe,
);

is $_ => array {
    item hash {
        field id      => 3;
        field article => hash { field id => 3; etc() };
        field unit    => hash { field id => 3; etc() };
        etc();
    };
    item hash {
        field id      => 2;
        field article => hash { field id => 1; etc() };
        field unit    => hash { field id => 2; etc() };
        etc();
    };
    item hash {
        field id      => 1;
        field article => hash { field id => 2; etc() };
        field unit    => hash { field id => 1; etc() };
        field value   => 15;
        etc();
    };
    item hash {    # not only same IDs but same hashrefs
        field id      => 4;
        field article => D();    #exact_ref( $_->[2]{article} );
        field unit    => D();    #exact_ref( $_->[2]{unit} );
        field value   => 10;
        etc();
    };
},
  "... ingredients"
  for $importer->ingredients;

is $importer->identify_candidates() => exact_ref($importer),
  '$importer->identify_candidates() returns $importer';

is $importer->source_articles => array {
    item hash { field target_candidate => U(); field name => 'flour'; etc() };
    item hash { field target_candidate => U(); field name => 'salt';  etc() };
    item hash { field target_candidate => U(); field name => 'water'; etc() };
},
  "... source_articles";

is $importer->source_units => array {
    item hash { field target_candidate => U(); field long_name => 'grams';     etc() };
    item hash { field target_candidate => U(); field long_name => 'kilograms'; etc() };
    item hash { field target_candidate => U(); field long_name => 'liters';    etc() };
},
  "... source_units";

is $importer->target_articles => [], "... target_articles";
is $importer->target_units    => [], "... target_units";

my $quantity = $target_project->quantities->create( { name => __FILE__ } );

my @articles = $target_project->articles->populate(
    [    # NOT alphabetic order
        { name => 'lava',  comment => 'something unrelated' },
        { name => 'flour', comment => 'same name' },
    ]
);

my @units = $target_project->units->populate(
    [
        [ 'quantity_id', 'space', 'short_name', 'long_name' ],                      # NOT alphabetic order
        [ $quantity->id, 1,       'xxx',        'kilograms' ],                      # same long_name
        [ $quantity->id, 1,       'g',          'grams with a different name' ],    # same short_name
    ]
);

ok $importer = Coocook::Model::RecipeImporter->new(
    project => $target_project,
    recipe  => $source_recipe,
);

ok $importer->identify_candidates, "identify_candidates()";

is $importer->source_articles => array {
    item hash {
        field name             => 'flour';
        field target_candidate => hash { field id => $articles[1]->id; etc() };
        etc();
    };
    item hash {
        field name             => 'salt';
        field target_candidate => U();
        etc();
    };
    item hash {
        field name             => 'water';
        field target_candidate => U();
        etc();
    };
},
  "... source_articles";

is $importer->source_units => array {
    item hash {
        field long_name        => 'grams';
        field target_candidate => hash { field id => $units[1]->id; etc() };
        etc();
    };
    item hash {
        field long_name        => 'kilograms';
        field target_candidate => hash { field id => $units[0]->id; etc() };
        etc();
    };
    item hash {
        field long_name        => 'liters';
        field target_candidate => U();
        etc();
    };
},
  "... source_units";

is $importer->target_articles => array {
    item hash { field name => 'flour'; etc() };
    item hash { field name => 'lava';  etc() };
},
  "... target_articles";

is $importer->target_units => array {
    item hash { field short_name => 'g';         etc() };
    item hash { field long_name  => 'kilograms'; etc() };
},
  "... target_units";

like dies { $importer->import_data( ingredients => {} ) } => qr/missing mapping/;

like dies {
    $importer->import_data(
        ingredients => { $importer->ingredients->[0]{id} => { article => 99999, unit => 99999 } } )
} => qr/invalid (article|unit)/;

is $target_project->recipes->count  => 0;
is $target_project->articles->count => scalar(@articles);
is $target_project->units->count    => scalar(@units);

$target_project->search_related($_)->delete for qw< articles units recipes >;

note "Importing articles and units from source project ...";
$target_project->search_related($_)->delete for 'articles', 'quantities';
Coocook::Model::ProjectImporter->new->import_data(
    $source_project => $target_project,
    [qw< articles quantities units >]
);

ok $importer = Coocook::Model::RecipeImporter->new(
    project => $target_project,
    recipe  => $source_recipe,
);

ok $importer->identify_candidates, "identify_candidates()";

ok $_->{target_candidate}, "found target_candidate"
  for @{ $importer->source_articles }, @{ $importer->source_units };

my %ingredients = (
    map {
        $_->{id} =>
          { article => $_->{article}{target_candidate}{id}, unit => $_->{unit}{target_candidate}{id} }
    } @{ $importer->ingredients }
);

$ingredients{1}{comment} = my $comment = "comment from line " . __LINE__;
$ingredients{2} = { skip => 1 };

isa_ok my $target_recipe = $importer->import_data( ingredients => \%ingredients ),
  ['Coocook::Schema::Result::Recipe'],
  "return value of import_data()";

is [ $target_recipe->ingredients_sorted->hri->all ] => array {
    item hash { field value => 0.5; field comment => "";                  etc() };
    item hash { field value => 15;  field comment => $comment;            etc() };
    item hash { field value => 10;  field comment => "if you like salty"; etc() };
},
  "new recipe's ingredients";

todo "implement precheck or exception handling" => sub {
    like dies { $importer->import_data( ingredients => \%ingredients ) } => qr/recipe already exists/;
};

ok my $target_recipe2 =
  $importer->import_data( ingredients => \%ingredients, name => "foobar", servings => 42 );

is [ $target_project->recipes->hri->all ] => array {
    item hash { field name => "pizza";  field servings => 4;  etc() };
    item hash { field name => "foobar"; field servings => 42; etc() };
},
  "created recipes in target project";

is $target_recipe2->ingredients->count => 3,
  "number of created recipe ingredients";
