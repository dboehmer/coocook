use strict;
use warnings;

use lib 't/lib/';

use Coocook::Model::ProjectImporter;
use TestDB;
use Test::Deep;
use Test::Most;

my $schema = TestDB->new( { deploy => 1 } );

my $source_project = $schema->resultset('Project')->find(1);
my $source_recipe  = $schema->resultset('Recipe')->find(1);

my $target_project = $schema->resultset('Project')->create(
    {
        name        => "target project",
        description => __FILE__,
        owner       => 1
    }
);

use_ok 'Coocook::Model::RecipeImporter';

my $importer = new_ok 'Coocook::Model::RecipeImporter',
  [ project => $target_project, recipe => $source_recipe ];

cmp_deeply $_=> [
    superhashof(
        { id => 3, article => superhashof( { id => 3 } ), unit => superhashof( { id => 3 } ) }
    ),
    superhashof(
        { id => 2, article => superhashof( { id => 1 } ), unit => superhashof( { id => 2 } ) }
    ),
    superhashof(
        { id => 1, article => superhashof( { id => 2 } ), unit => superhashof( { id => 1 } ), value => 15 }
    ),
    superhashof(    # not only same IDs but same hashrefs
        { id => 4, article => shallow( $_->[2]{article} ), unit => shallow( $_->[2]{unit} ), value => 10 }
    ),
  ],
  "... ingredients"
  for $importer->ingredients;

is $importer->identify_candidates() => $importer,
  '$importer->identify_candidates() returns $importer';

cmp_deeply $importer->source_articles => [
    superhashof( { target_candidate => undef, name => 'flour' } ),
    superhashof( { target_candidate => undef, name => 'salt' } ),
    superhashof( { target_candidate => undef, name => 'water' } ),
  ],
  "... source_articles";

cmp_deeply $importer->source_units => [
    superhashof( { target_candidate => undef, long_name => 'grams' } ),
    superhashof( { target_candidate => undef, long_name => 'kilograms' } ),
    superhashof( { target_candidate => undef, long_name => 'liters' } ),
  ],
  "... source_units";

cmp_deeply $importer->target_articles => [], "... target_articles";
cmp_deeply $importer->target_units    => [], "... target_units";

my $quantity = $target_project->quantities->create( { name => __FILE__ } );

my @articles = $target_project->articles->populate(
    [    # NOT alphabetic order
        { name => 'lava',  comment => 'something unrelated' },
        { name => 'flour', comment => 'same name' },
    ]
);

my @units = $target_project->units->populate(
    [
        [ 'quantity', 'space', 'short_name', 'long_name' ],    # NOT alphabetic order
        [ $quantity->id, 1, 'xxx', 'kilograms' ],                      # same long_name
        [ $quantity->id, 1, 'g',   'grams with a different name' ],    # same short_name
    ]
);

$importer = new_ok 'Coocook::Model::RecipeImporter',
  [ project => $target_project, recipe => $source_recipe ];

ok $importer->identify_candidates, "identify_candidates()";

cmp_deeply $importer->source_articles => [
    superhashof( { name => 'flour', target_candidate => superhashof( { id => $articles[1]->id } ) } ),
    superhashof( { name => 'salt',  target_candidate => undef } ),
    superhashof( { name => 'water', target_candidate => undef } ),
  ],
  "... source_articles";

cmp_deeply $importer->source_units => [
    superhashof( { long_name => 'grams', target_candidate => superhashof( { id => $units[1]->id } ) } ),
    superhashof(
        { long_name => 'kilograms', target_candidate => superhashof( { id => $units[0]->id } ) }
    ),
    superhashof( { long_name => 'liters', target_candidate => undef } ),
  ],
  "... source_units";

cmp_deeply $importer->target_articles => [
    superhashof( { name => 'flour' } ),    #perltidy
    superhashof( { name => 'lava' } ),
  ],
  "... target_articles";

cmp_deeply $importer->target_units => [
    superhashof( { short_name => 'g' } ),           #perltidy
    superhashof( { long_name  => 'kilograms' } ),
  ],
  "... target_units";

throws_ok { $importer->import_data( ingredients => {} ) } qr/missing mapping/;

throws_ok {
    $importer->import_data(
        ingredients => { $importer->ingredients->[0]{id} => { article => 99999, unit => 99999 } } )
}
qr/invalid (article|unit)/;

is $target_project->recipes->count  => 0;
is $target_project->articles->count => scalar(@articles);
is $target_project->units->count    => scalar(@units);

$target_project->search_related($_)->delete for qw< articles units recipes >;

note "Importing articles and units from source project ...";
Coocook::Model::ProjectImporter->new->import_data(
    $source_project => $target_project,
    [qw< articles quantities units >]
);

$importer = new_ok 'Coocook::Model::RecipeImporter',
  [ project => $target_project, recipe => $source_recipe ];

ok $importer->identify_candidates, "identify_candidates()";

ok $_->{target_candidate}, "found target_candidate"
  for @{ $importer->source_articles }, @{ $importer->source_units };

my %ingredients = (
    map {
        $_->{id} =>
          { article => $_->{article}{target_candidate}{id}, unit => $_->{unit}{target_candidate}{id} }
    } @{ $importer->ingredients }
);
##note explain \%ingredients;

isa_ok my $target_recipe =
  $importer->import_data( ingredients => \%ingredients ) => 'Coocook::Schema::Result::Recipe',
  "return value of import_data()";

cmp_deeply $_ => [
    superhashof( { position => 1, value => 0.5 } ),
    superhashof( { position => 2, value => 1 } ),
    superhashof( { position => 3, value => 15 } ),
    superhashof( { position => 4, value => 10, comment => "if you like salty" } ),
  ],
  "new recipe's ingredients"
  or note explain $_
  for [ $target_recipe->ingredients->hri->all ];

{
    local $TODO = "implement precheck or exception handling";
    throws_ok { $importer->import_data( ingredients => \%ingredients ) } qr/recipe already exists/;
}

ok my $target_recipe2 =
  $importer->import_data( ingredients => \%ingredients, name => "foobar", servings => 42 );

cmp_deeply [ $target_project->recipes->hri->all ] => [
    superhashof( { name => "pizza",  servings => 4 } ),
    superhashof( { name => "foobar", servings => 42 } ),
  ],
  "created recipes in target project";

is $target_recipe2->ingredients->count => 4,
  "number of created recipe ingredients";

done_testing;
