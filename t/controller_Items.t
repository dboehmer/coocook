use strict;
use warnings;

use lib 't/lib';

use TestDB;
use Test::Coocook;
use Test::Most tests => 3;

my $t = Test::Coocook->new();

$t->get('/');
$t->login_ok( 'john_doe', 'P@ssw0rd' );

subtest "send invalid list ID" => sub {
    $t->get_ok('/project/test/items/unassigned');

    ok $t->submit_form(

        with_fields => {
            assign2 => 1,      # valid but should not be executed
            assign5 => 999,    # invalid -> error 400
        },
        strict_forms => 0,     # no option with value 999 exists
      ),
      "assign first item to list 1, 2nd item to inexistent list";
    $t->status_is(400);

    $t->get_ok('/project/test/items/unassigned');
    $t->content_contains( 'assign2', "item wasn't assigned by errornous request" );
};

subtest "successfully assign items" => sub {
    $t->get_ok('/project/test/items/unassigned');

    $t->submit_form_ok(
        {
            with_fields => { assign2 => 1 },
        },
        "assign first item to purchase list 1"
    );

    $t->get_ok('/project/test/items/unassigned');
    $t->content_lacks( 'assign2', "item was assigned" );
};
