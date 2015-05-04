use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Coocook';
use Coocook::Controller::Ingredient;

ok( request('/ingredient')->is_success, 'Request should succeed' );
done_testing();
