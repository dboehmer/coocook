use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Coocook';
use Coocook::Controller::Article;

ok( !request('/articles')->is_error, 'Request should succeed' );
done_testing();
