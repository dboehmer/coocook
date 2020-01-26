use strict;
use warnings;

use lib 't/lib';

use DateTime;
use TestDB;
use Test::Coocook;
use Test::Most tests => 25;

my $t = Test::Coocook->new();

my $project = $t->schema->resultset('Project')->create(
    {
        name        => 'Test Project',
        description => "",
        owner       => 1,
    }
);

$t->get_ok('/project/test-project');
$t->content_lacks( 'message-info', "no message at all if not logged in" );

$t->login_ok( john_doe => 'P@ssw0rd' );
message_contains('fresh project');

$project->create_related( tags => { name => 'foo' } );
message_like(qr/ lacks .+ quantities /x);

my $quantity = $project->create_related( quantities => { name => 'weight' } );
message_like(qr/ lacks .+ units /x);

my $unit = $quantity->create_related(
    units => { project => $project->id, short_name => 'kg', long_name => 'kilograms', space => 0 } );
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
      { prepare => 0, value => 42, unit => $unit->id, article => $article->id, comment => "" } );
message_like(qr/ lacks .+ purchase\ lists /x);

my $list =
  $project->create_related( purchase_lists => { date => '2000-01-01', name => "purchase list" } );
message_contains('items');

$ingredient->assign_to_purchase_list($list);
message_contains('stale');

$list->update( { date => $list->format_date( DateTime->today->add( years => 1 ) ) } );
message_contains('print');

sub message_contains {
    $t->get_ok('/project/test-project');
    $t->text_contains(shift)
      or note $t->text;
}

sub message_like {
    $t->get_ok('/project/test-project');
    $t->text_like(shift)
      or note $t->text;
}
