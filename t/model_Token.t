use strict;
use warnings;

use Test::Most tests => 7;

use_ok 'Coocook::Model::Token';

my $token = new_ok 'Coocook::Model::Token';

isa_ok my $token2 = $token->new() => 'Coocook::Model::Token',
  "->new() on Token instance";

isa_ok $token->new() => 'Coocook::Model::Token',
  "->new on Token instance";

like $token->to_base64 => qr/ ^ [a-zA-Z0-9-_]+ $ /x,
  "->to_base64 is URL safe";

isnt $token->to_base64 => $token2->to_base64,
  "->base64() of two tokens differ";

ok $token->to_salted_hash ne $token->to_salted_hash,
  "->to_salted_hash creates 2 different results in same Token";
