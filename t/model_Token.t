use strict;
use warnings;

use Test::Most tests => 5;

use_ok 'Coocook::Model::Token';

my $token = new_ok 'Coocook::Model::Token';

isa_ok $token->new() => 'Coocook::Model::Token',
  "->new on Token instance";

like $token->to_base64 => qr/ ^ [a-zA-Z0-9-_]+ $ /x,
  "->to_base64 is URL safe";

ok $token->to_salted_hash ne $token->to_salted_hash,
  "->to_salted_hash creates 2 different results in same Token";
