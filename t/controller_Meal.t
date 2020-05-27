use strict;
use warnings;

use lib 't/lib';

use TestDB;
use Test::Coocook;
use Test::Most tests => 2;

my $t = Test::Coocook->new();

my $schema = $t->schema;

$t->get('/');
$t->login_ok( 'john_doe', 'P@ssw0rd' );

subtest "delete meal" => sub {
    my $meal_id = 2;

    $t->get_ok('/project/1/Test-Project/edit');
    $t->content_lacks('Delete meal');
    ok $schema->resultset('Meal')->find($meal_id)->dishes->results_exist, "Dishes exist in meal";
    $t->post("/project/1/Test-Project/meals/$meal_id/delete_dishes");
    ok !$schema->resultset('Meal')->find($meal_id)->dishes->results_exist, "Dishes were deleted";
    $t->content_lacks('Delete meal');
    $t->content_contains('has pending dishes to prepare');
    $schema->resultset('Meal')->find($meal_id)
      ->prepared_dishes->update( { prepare_at_meal_id => undef } );
    $t->reload();
    $t->content_contains('Delete meal');
    $t->post("/project/1/Test-Project/meals/$meal_id/delete");
    ok !$schema->resultset('Meal')->find($meal_id), "Meal was successfully eaten up";
  }
