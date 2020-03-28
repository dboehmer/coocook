use strict;
use warnings;

use lib 't/lib';

use Test::Coocook;
use Test::Most tests => 9;

my $t = Test::Coocook->new;

$t->schema->resultset('Project')->exists( { name => my $private_project = 'Other Project' } )
  or die "test broken";

$t->schema->resultset('Recipe')->exists( { name => my $private_recipe = 'rice pudding' } )
  or die "test broken";

$t->get_ok('/');

$t->text_contains('Test Project');
$t->text_lacks($private_project);

$t->text_contains('pizza');
$t->text_lacks($private_recipe);

$t->follow_link_ok( { text => 'Test Project' } );
$t->base_is('https://localhost/project/1/Test-Project');

$t->back();
$t->follow_link_ok( { text => 'pizza' } );
$t->base_is('https://localhost/recipe/1/pizza');
