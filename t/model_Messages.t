use strict;
use warnings;

use Test::Deep;
use Test::MockObject;
use Test::Most tests => 11;

use_ok 'Coocook::Model::Messages';

my $messages = new_ok 'Coocook::Model::Messages';

can_ok $messages, 'debug';
can_ok $messages, 'info';
can_ok $messages, 'warn';
can_ok $messages, 'error';

ok $messages->error("foo"), "add error as plain string";

cmp_deeply $messages->messages => [ { type => 'error', text => 'foo' } ];

is $messages->clear => $messages, "clear() returns \$messages";

cmp_deeply $messages->messages => [], "is empty";

$messages->add( error => "string1" );
$messages->add( { type => 'error', text => "string2" } );

cmp_deeply $messages->messages =>
  [ { type => 'error', text => "string1" }, { type => 'error', text => "string2" } ];
