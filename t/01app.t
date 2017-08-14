#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Coocook';

ok( !request('/')->is_error, 'Request should succeed' );

done_testing();
