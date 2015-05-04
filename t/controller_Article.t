use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Coocook';
use Coocook::Controller::Article;

ok( request('/article')->is_success, 'Request should succeed' );
done_testing();
