use Test2::V0;

use Coocook::Model::ProjectImporter;

use lib 't/lib/';
use Test::Coocook;

plan(10);

my $t = Test::Coocook->new;

$t->schema->resultset($_)->search( { project_id => 2 } )->delete() for 'Article', 'Quantity';
Coocook::Model::ProjectImporter->new->import_data(
    $t->schema->resultset('Project')->find(1),
    $t->schema->resultset('Project')->find(2),
    [qw< articles quantities units >]
);

$t->schema->resultset('Recipe')->create(
    {
        project_id  => 2,
        name        => 'Spätzle über Bratklößchen',    # contains all German umlauts
        servings    => 42,
        preparation => __FILE__,
        description => __FILE__,
    }
);

$t->get_ok('/project/2/Other-Project/recipes/import/1');

$t->login_ok( 'john_doe', 'P@ssw0rd' );

$t->text_contains("Import recipe pizza from project Test")
  or note $t->text;

$t->content_contains('existingRecipeNames');

# JSON data in <script> element
$t->content_contains( 'Spätzle über Bratklößchen', "Unicode characters encoded properly" )
  or note $t->content;

$t->form_id('import') || die;
$t->submit_form_ok( { button => 'import' } );

$t->base_like(qr{ ^https://localhost/project/2/Other-Project/recipe/ \d+ $ }x);

$t->get_ok('/project/2/Other-Project/recipes/import/1');    # again

$t->form_id('import') || die;
$t->submit_form_ok( { button => 'import' } );

$t->text_like(qr/already exist/);
