#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';
use TestDB;
use Test::More;

BEGIN { our $SCHEMA = TestDB->new() }

use Catalyst::Test 'Coocook';

ok( !request('/')->is_error, 'Request should succeed' );

ok my $res = request('http://localhost/'), "request http://localhost/";

is $res->code => 302, "... HTTP response code is 302";

is $res->header('Location') => 'https://localhost/', "Location header is HTTPS";

done_testing();
