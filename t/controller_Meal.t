use strict;
use warnings;

use lib 't/lib';

use Test::Coocook;
use Test::Most tests => 4;

my $t = Test::Coocook->new();

my $schema = $t->schema;

$t->get('/');
$t->login_ok( 'john_doe', 'P@ssw0rd' );

subtest "delete meal" => sub {
    my $meal_id = 2;

    $t->get_ok('/project/1/Test-Project/edit');
    $t->content_lacks('Delete meal');

    $t->content_lacks('cannot be deleted, because it contains dishes');
    $t->post("/project/1/Test-Project/meals/$meal_id/delete");
    $t->content_contains('cannot be deleted, because it contains dishes');

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
};

subtest "create meal" => sub {
    $t->get_ok('/project/1/Test-Project/edit');
    $t->content_lacks('Autonomous Meal');
    $t->submit_form_ok(
        {
            form_name   => 'create_meal',
            form_number => 6,
            with_fields => {
                name    => 'Autonomous Meal',
                comment => 'The bots are cooking!',
            },
            strict_forms => 0,
        },
        "create a meal with name 'Autonomous Meal'"
    );
    $t->get_ok('/project/1/Test-Project/edit');
    $t->content_contains('Autonomous Meal');
};

subtest "update meal" => sub {
    $t->get_ok('/project/1/Test-Project/edit');
    $t->content_lacks('Meal for Robots');
    $t->content_contains('Autonomous Meal');
    $t->submit_form_ok(
        {
            form_name   => 'update_meal',
            form_number => 7,
            with_fields => {
                name    => 'Meal for Robots',
                comment => 'Crunch! Crunch! Crunch!',
            },
            strict_forms => 0,
        },
        "change name and comment for meal with name 'Autonomous Meal' to 'Meal for Robots'"
    );
    $t->get_ok('/project/1/Test-Project/edit');
    $t->content_lacks('Autonomous Meal');
    $t->content_contains('Meal for Robots');
};
