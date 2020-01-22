use strict;
use warnings;
use utf8;    # German umlauts in this source file

use open ':locale';    # respect encoding configured in terminal

use lib 't/lib/';

use Coocook::Model::ProjectImporter;
use Test::Coocook;
use Test::Most tests => 10;

my $t = Test::Coocook->new;

Coocook::Model::ProjectImporter->new->import_data(
    $t->schema->resultset('Project')->find(1),
    $t->schema->resultset('Project')->find(2),
    [qw< articles quantities units >]
);

$t->schema->resultset('Recipe')->create(
    {
        project     => 2,
        name        => 'Spätzle über Bratklößchen',    # contains all German umlauts
        servings    => 42,
        preparation => __FILE__,
        description => __FILE__,
    }
);

$t->get_ok('/project/Other-Project/recipes/import/1');

$t->login_ok( 'john_doe', 'P@ssw0rd' );

$t->text_contains("Import recipe pizza from project Test")
  or note $t->text;

$t->content_contains('existingRecipeNames');

$t->content_contains( 'Spätzle über Bratklößchen', "Unicode characters encoded properly" )
  or note $t->content;

$t->form_id('import') || die;
$t->submit_form_ok( { button => 'import' } );

$t->base_is('https://localhost/project/Other-project/recipe/3');

$t->get_ok('/project/Other-Project/recipes/import/1');    # again

$t->form_id('import') || die;
$t->submit_form_ok( { button => 'import' } );

$t->text_like(qr/already exist/);
