use strict;
use warnings;

use Test::Output;
use Test::Most tests => 4;

use_ok 'Coocook::Script::Get';

throws_ok { Coocook::Script::Get->new_with_options( ARGV => [] ) } qr/usage/i,
  "displays usage without arguments";

ok my $app = Coocook::Script::Get->new_with_options( ARGV => ['/internal_server_error'] );

stdout_like { $app->run } qr/Oo+ps/, "GET /internal_server_error contains Ooops";
