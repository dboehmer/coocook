use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Coocook';
use Coocook::Controller::Unit;

ok( !request('/units')->is_error, 'Request should succeed' );
done_testing();
