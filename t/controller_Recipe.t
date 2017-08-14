use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Coocook';
use Coocook::Controller::Recipe;

ok( !request('/recipes')->is_error, 'Request should succeed' );
done_testing();
