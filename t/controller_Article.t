use strict;
use warnings;

use open ':locale';
use utf8;

use lib 't/lib';

use TestDB;
use Test::Coocook;
use Test::Most tests => 14;

my $t = Test::Coocook->new();

$t->get('/');
$t->login_ok( 'john_doe', 'P@ssw0rd' );

$t->follow_link_ok( { text => 'Test Project' } );
$t->follow_link_ok( { text => 'Articles' } );

$t->follow_link_ok( { text => 'New article' } );

$t->submit_form_ok( { with_fields => { name => 'aether' } }, "create article" );

is $t->schema->resultset('Article')->find( { name => 'aether' } )->units->count => 0,
  "... new article has no units";

$t->follow_link_ok( { text => 'Articles' } );

$t->text_contains('aether');

$t->follow_link_ok( { text => 'cheese' } );

my $update_req;

subtest "invalid unit IDs" => sub {
    my $res = $t->submit_form( with_fields => { units => 9999 }, strict_forms => 0 );
    $t->status_is(400);
    $t->text_contains('invalid');

    $update_req = $res->request;
};

$t->back();

subtest "deselect units that are in use" => sub {
    my $form_data = $update_req->content;
    $form_data =~ s/&units=$_// or die for 2, 9999;    # remove IDs sent before

    ok $t->post( $update_req->uri, content => $form_data );
    $t->status_is(400);
    $t->text_contains("in use");

    $t->back();
};

# select unit 3 (liters), I couldn't get this working by passing units=>[...] to submit_form()
$t->form_number(2);
$t->tick( units => 3 );

$t->submit_form_ok( { with_fields => { name => 'cheddar' } }, "update article" );

$t->text_contains('cheddar');

is
  join( ',' =>
      sort $t->schema->resultset('Article')->find( { name => 'cheddar' } )
      ->units->get_column('short_name')->all ) => 'g,kg,l';
