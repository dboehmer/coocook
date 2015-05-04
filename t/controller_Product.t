use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Coocook';
use Coocook::Controller::Product;

ok( request('/product')->is_success, 'Request should succeed' );
done_testing();
