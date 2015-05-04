use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Coocook';
use Coocook::Controller::Recipe;

ok( request('/recipe')->is_success, 'Request should succeed' );
done_testing();
