use strict;
use warnings;

use Test::Most;

use Catalyst::Test 'Coocook';

ok my $res = request('http://localhost/'), "request http://localhost/";

is $res->code => 302, "... HTTP response code is 302";

is $res->header('Location') => 'https://localhost/', "Location header is HTTPS";

done_testing;
