use strict;
use warnings;

use lib 't/lib/';

use Test::Coocook;
use Test::Most tests => 9;

my $t = Test::Coocook->new;

$t->get_ok('/recipes');
$t->follow_link_ok( { text => 'pizza' } );
$t->base_is('https://localhost/recipe/1/pizza');

$t->get_ok('https://localhost/recipe/1/PIZZA');
$t->base_is('https://localhost/recipe/1/pizza');

$t->get_ok('https://localhost/recipe/1/any-other-string');
$t->base_is('https://localhost/recipe/1/pizza');

ok $t->get($_), "GET $_" for 'https://localhost/recipe/999/pizza';
$t->status_is(404);
