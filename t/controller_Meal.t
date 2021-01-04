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
    $t->text_lacks('Delete meal');

    $t->text_lacks('cannot be deleted, because it contains dishes');
    $t->post("/project/1/Test-Project/meals/$meal_id/delete");
    $t->text_contains('cannot be deleted, because it contains dishes');

    ok $schema->resultset('Meal')->find($meal_id)->dishes->results_exist, "Dishes exist in meal";
    $t->post("/project/1/Test-Project/meals/$meal_id/delete_dishes");
    ok !$schema->resultset('Meal')->find($meal_id)->dishes->results_exist, "Dishes were deleted";

    $t->lacks_button_ok( my $button = 'delete-meal' );
    $t->text_contains('has pending dishes to prepare');
    $schema->resultset('Meal')->find($meal_id)
      ->prepared_dishes->update( { prepare_at_meal_id => undef } );
    $t->reload_ok();
    $t->form_name("delete-meal$meal_id");
    $t->button_exists_ok($button);
    $t->post("/project/1/Test-Project/meals/$meal_id/delete");
    ok !$schema->resultset('Meal')->find($meal_id), "Meal was successfully eaten up";
};

my $meal_name1 = 'Autonomous Meal';
my $meal_name2 = 'Meal for Robots';

subtest "create meal" => sub {
    $t->get_ok('/project/1/Test-Project/edit');
    $t->text_lacks($meal_name1);
    $t->submit_form_ok(
        {
            form_name   => 'create_meal',
            form_number => 6,
            with_fields => {
                name    => $meal_name1,
                comment => 'The bots are cooking!',
            },
            strict_forms => 0,
        },
        "create a meal with name '$meal_name1'"
    );
    $t->get_ok('/project/1/Test-Project/edit');
    $t->text_contains($meal_name1);
};

subtest "update meal" => sub {
    $t->get_ok('/project/1/Test-Project/edit');
    $t->text_lacks('Meal for Robots');
    $t->text_contains($meal_name1);
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
        "change name and comment for meal with name '$meal_name1' to 'Meal for Robots'"
    );
    $t->get_ok('/project/1/Test-Project/edit');
    $t->text_lacks($meal_name1);
    $t->text_contains('Meal for Robots');
};
