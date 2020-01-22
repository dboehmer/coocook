use strict;
use warnings;
use utf8;    # German umlauts in this source file

use open ':locale';    # respect encoding configured in terminal

use lib 't/lib/';

use Test::Coocook;
use Test::Most tests => 5;

my $t = Test::Coocook->new;

$t->get_ok('/project/Other-Project/recipes/import/1');

$t->login_ok( 'john_doe', 'P@ssw0rd' );

$t->text_contains("Import recipe pizza from project Test")
  or note $t->text;

$t->content_contains('existingRecipeNames');

$t->schema->resultset('Recipe')->create(
    {
        project     => 2,
        name        => 'Spätzle über Bratklößchen',    # contains all German umlauts
        servings    => 42,
        preparation => __FILE__,
        description => __FILE__,
    }
);

$t->reload();

$t->content_contains( 'Spätzle über Bratklößchen', "Unicode characters encoded properly" )
  or note $t->content;
