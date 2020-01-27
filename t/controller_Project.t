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

$t->get_ok('/project/test-project');
$t->text_like(qr/fresh project/)
  or note $t->text;

$project->create_related( tags => { name => 'foo' } );

$t->get_ok('/project/test-project');
$t->text_like(qr/ lacks .+ quantities /x)
  or note $t->text;

my $quantity = $project->create_related( quantities => { name => 'weight' } );

$t->get_ok('/project/test-project');
$t->text_like(qr/ lacks .+ units /x)
  or note $t->text;

my $unit = $quantity->create_related(
    units => { project => $project->id, short_name => 'kg', long_name => 'kilograms', space => 0 } );

$t->get_ok('/project/test-project');
$t->text_like(qr/ lacks .+ articles /x)
  or note $t->text;

my $article = $project->create_related(
    articles => {
        name    => 'apples',
        comment => '',
    }
);
$article->add_to_units($unit);

$t->get_ok('/project/test-project');
$t->text_like(qr/ lacks .+ meals .+ recipes? /msx)
  or note $t->text;

$project->create_related(
    recipes => { name => 'apple pie', servings => 42, preparation => '', description => '' } );

$t->get_ok('/project/test-project');
$t->text_like(qr/ lacks .+ meals (?! .+ recipes ) /x)
  or note $t->text;

my $meal =
  $project->create_related( meals => { date => '2000-01-01', name => "lunch", comment => "" } );

$t->get_ok('/project/test-project');
$t->text_like(qr/ lacks .+ dishes (?! .+ ( meals | recipes ) ) /x)
  or note $t->text;

my $dish = $meal->create_related( dishes =>
      { name => 'apple pie', servings => 42, preparation => "", description => "", comment => "" } );

my $ingredient = $dish->create_related( ingredients =>
      { prepare => 0, value => 42, unit => $unit->id, article => $article->id, comment => "" } );

$t->get_ok('/project/test-project');
$t->text_like(qr/ lacks .+ purchase\ lists /x)
  or note $t->text;

my $list =
  $project->create_related( purchase_lists => { date => '2000-01-01', name => "purchase list" } );

$t->get_ok('/project/test-project');
$t->text_like(qr/ items /x)
  or note $t->text;

$ingredient->assign_to_purchase_list($list);

$t->get_ok('/project/test-project');
$t->text_like(qr/ stale /x)
  or note $t->text;

$list->update( { date => $list->format_date( DateTime->today->add( years => 1 ) ) } );

$t->get_ok('/project/test-project');
$t->text_like(qr/ print /x)
  or note $t->text;
