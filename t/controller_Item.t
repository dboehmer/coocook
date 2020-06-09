use strict;
use warnings;

use lib 't/lib';

use TestDB;
use Test::Coocook;
use Test::Most tests => 4;

my $t = Test::Coocook->new();

$t->get('/');
$t->login_ok( 'john_doe', 'P@ssw0rd' );

subtest "send invalid list ID" => sub {
    $t->get_ok('/project/1/Test-Project/items/unassigned');

    ok $t->submit_form(

        with_fields => {
            assign2 => 1,      # valid but should not be executed
            assign5 => 999,    # invalid -> error 400
        },
        strict_forms => 0,     # no option with value 999 exists
      ),
      "assign first item to list 1, 2nd item to inexistent list";
    $t->status_is(400);

    $t->get_ok('/project/1/Test-Project/items/unassigned');
    $t->content_contains( 'assign2', "item wasn't assigned by errornous request" );
};

subtest "successfully assign items" => sub {
    $t->get_ok('/project/1/Test-Project/items/unassigned');

    $t->submit_form_ok(
        {
            with_fields => { assign2 => 1 },
        },
        "assign first item to purchase list 1"
    );

    $t->get_ok('/project/1/Test-Project/items/unassigned');
    $t->content_lacks( 'assign2', "item was assigned" );
};

subtest "change item total" => sub {
    $t->get_ok('/project/1/Test-Project/purchase_list/1');

    $t->content_contains('value="42.5"');

    #print $t->content."\n";

    $t->content_lacks('rounding difference');

    $t->submit_form_ok(
        {
            form_name   => 'total',
            form_number => 6,
            with_fields => { total => 39 },
        },
        "Set total value to 39"
    );

    $t->get_ok('/project/1/Test-Project/purchase_list/1');

    $t->content_lacks('value="42.5"');

    $t->content_contains('value="39"');

    $t->content_contains('-3.5');

    $t->content_contains('rounding difference');

    $t->submit_form_ok(
        {
            form_name   => 'remove-offset',
            form_number => 10,
        },
        "Remove offset"
    );

    $t->get_ok('/project/1/Test-Project/purchase_list/1');

    $t->content_lacks('rounding difference');

    $t->content_contains('value="42.5"');

    $t->content_contains('12.5');

    $t->content_lacks('30');

    $t->submit_form_ok(
        {
            form_number => 8,
        },
        "Remove ingredient"
    );

    $t->content_lacks('12.5');

    $t->content_contains('30');

    $t->content_contains('value="1000"');

    $t->content_lacks('value="1"');

    $t->submit_form_ok(
        {
            form_number => 5,
        },
        "Convert item to kg"
    );

    $t->content_lacks('value="1000"');

    $t->content_contains('value="1"');

};
