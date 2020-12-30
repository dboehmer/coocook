use strict;
use warnings;

use lib 't/lib';

use DateTime;
use TestDB;
use Test::Coocook;
use Test::Most tests => 40;

my $t = Test::Coocook->new();

subtest "project not found" => sub {
    ok $t->get('https://localhost/project/999/foobar');
    $t->status_is(404);
};

# TODO deprecated: remove fallback and UNIQUE constraint on projects.name[_fc]
subtest "deprecated: fallback redirects from old URL scheme" => sub {
    $t->redirect_is(
        'https://localhost/project/Test-Project/foo?bar=baz' =>
          "https://localhost/project/1/Test-Project/foo?bar=baz",
        301    # permanent
    );

    $t->redirect_is(
        'https://localhost/project/Test-Project/foo/bar/baz' =>
          "https://localhost/project/1/Test-Project/foo/bar/baz",
        301    # permanent
    );

    ok $t->get($_), "GET $_" for 'https://localhost/project/doesnt-exist/foo';
    $t->status_is(404);
};

subtest "redirect to fix URLs" => sub {
    $t->redirect_is(
        "https://localhost/project/1" => "https://localhost/project/1/Test-Project",
        301    # permanent
    );

    # this endpoint doesn't check any permissions but $c->go()s to another action
    # this might be dangerous if check don't happen there
    $t->redirect_is(
        "https://localhost/project/2" => "https://localhost/login?redirect=%2Fproject%2F2",
        302,    # temporary
        "/project/2 shortcut doesn't allow access to private projects, doesn't reveal their name"
    );

    $t->redirect_is(
        "https://localhost/project/1/tEST-pROJECT/recipes" =>
          "https://localhost/project/1/Test-Project/recipes",
        301     # permanent
    );

    $t->redirect_is(
        "https://localhost/project/2/I-cant-know-this-projects-name/recipes" =>
          "https://localhost/login?redirect=%2Fproject%2F2%2FI-cant-know-this-projects-name%2Frecipes",
        302,    # temporary
        "/project/2/foobar doesn't reveal the real name of project 2",
    );

    $t->redirect_is(
        "https://localhost/project/1/completely-different-string/recipes" =>
          "https://localhost/project/1/Test-Project/recipes",
        301     # permanent
    );

    # with path arguments
    $t->redirect_is(
        "https://localhost/project/1/tEST-pROJECT/recipe/1" =>
          "https://localhost/project/1/Test-Project/recipe/1",
        301     # permanent
    );

    $t->redirect_is(
        "https://localhost/project/1/completely-different-string/recipe/1" =>
          "https://localhost/project/1/Test-Project/recipe/1",
        301     # permanent
    );

    # with query string
    $t->redirect_is(
        "https://localhost/project/1/tEST-pROJECT/recipes?keyword" =>
          "https://localhost/project/1/Test-Project/recipes?keyword",
        301     # permanent
    );

    $t->redirect_is(
        "https://localhost/project/1/tEST-pROJECT/recipes?key=val" =>
          "https://localhost/project/1/Test-Project/recipes?key=val",
        301     # permanent
    );
};

subtest import => sub {
    $t->get_ok('/');
    $t->login_ok( john_doe => 'P@ssw0rd' );

    my $project = $t->schema->resultset('Project')->create(
        {
            name        => 'empty project',
            description => "",
            owner_id    => 1,
        }
    );
    my $id = $project->id;

    $t->get_ok("/project/$id/Statistics-Project/import");
    $t->content_lacks('disabled');

    $t->get_ok('/project/1/Test-Project/import');
    $t->content_contains('disabled');

    # former bug: properties are stored in a package variable and were
    # modified through a reference given by Model::ProjectImporter
    $t->get_ok("/project/$id/Statistics-Project/import");
    $t->content_lacks('disabled');

    $t->logout_ok();
};

my $project = $t->schema->resultset('Project')->create(
    {
        name        => 'Statistics Project',
        description => "",
        owner_id    => 1,
        archived    => '2000-01-01 00:00:00',
    }
);

my $id = $project->id;

message_contains('archived');
$t->content_lacks('Un-archive this project');

$t->login_ok( john_doe => 'P@ssw0rd' );
message_contains('archived');
$t->content_contains('Un-archive this project');
$t->logout_ok();

$project->update( { archived => undef } );

message_lacks( 'message-info', "no message at all if not logged in" );

$t->login_ok( john_doe => 'P@ssw0rd' );
message_contains('fresh project');

{
    my $meal =
      $project->create_related( meals => { date => '1970-01-01', name => 'breakfast', comment => '' } );

    message_like(qr/ lacks .+ quantities /x);
    $meal->delete();
}

$project->create_related( tags => { name => 'foo' } );
message_like(qr/ lacks .+ quantities /x);

my $quantity = $project->create_related( quantities => { name => 'weight' } );
message_like(qr/ lacks .+ units /x);

my $unit = $quantity->create_related(
    units => { project_id => $project->id, short_name => 'kg', long_name => 'kilograms', space => 0 } );
message_like(qr/ lacks .+ articles /x);

my $article = $project->create_related(
    articles => {
        name    => 'apples',
        comment => '',
    }
);
$article->add_to_units($unit);
message_like(qr/ lacks .+ meals .+ recipes? /msx);

$project->create_related(
    recipes => { name => 'apple pie', servings => 42, preparation => '', description => '' } );
message_like(qr/ lacks .+ meals (?! .+ recipes ) /x);

my $meal =
  $project->create_related( meals => { date => '2000-01-01', name => "lunch", comment => "" } );
message_like(qr/ lacks .+ dishes (?! .+ ( meals | recipes ) ) /x);

my $dish = $meal->create_related( dishes =>
      { name => 'apple pie', servings => 42, preparation => "", description => "", comment => "" } );
my $ingredient = $dish->create_related( ingredients =>
      { prepare => 0, value => 42, unit_id => $unit->id, article_id => $article->id, comment => "" } );
message_like(qr/ lacks .+ purchase\ lists /x);

my $list =
  $project->create_related( purchase_lists => { date => '2000-01-01', name => "purchase list" } );
message_contains('items');

$ingredient->assign_to_purchase_list($list);
message_contains('stale');

$list->update( { date => $list->format_date( DateTime->today->add( years => 1 ) ) } );
message_contains('print');

sub message_contains {
    $t->get_ok("/project/$id/Statistics-Project");
    $t->text_contains(@_)
      or note $t->text;
}

sub message_lacks {
    $t->get_ok("/project/$id/Statistics-Project");
    $t->text_lacks(@_)
      or note $t->text;
}

sub message_like {
    $t->get_ok("/project/$id/Statistics-Project");
    $t->text_like(@_)
      or note $t->text;
}

subtest "project deletion" => sub {
    $t->get_ok('/project/1/Test-Project/settings');

    $t->submit_form_ok( { form_name => 'delete', with_fields => { confirmation => 'foo' } } );
    $t->text_contains("not deleted");

    $t->submit_form_ok( { form_name => 'delete', with_fields => { confirmation => 'Test Project' } } );
    $t->base_is('https://localhost/');
    $t->text_contains('Test Project');
    $t->text_contains('deleted');

    $t->reload();
    $t->text_lacks('Test Project')
      or note $t->content;
};
