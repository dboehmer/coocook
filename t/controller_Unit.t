use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Coocook';
use Coocook::Controller::Unit;

ok( request('/unit')->is_success, 'Request should succeed' );
done_testing();
