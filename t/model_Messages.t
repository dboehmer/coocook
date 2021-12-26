use Test2::V0;

use Coocook::Model::Messages;
use Test::MockObject;

plan(10);

ok my $messages = Coocook::Model::Messages->new();

can_ok $messages, 'debug';
can_ok $messages, 'info';
can_ok $messages, 'warn';
can_ok $messages, 'error';

ok $messages->error("foo"), "add error as plain string";

is $messages->messages => [ { type => 'error', text => 'foo' } ];

is $messages->clear => $messages, "clear() returns \$messages";

is $messages->messages => [], "is empty";

$messages->add( error => "string1" );
$messages->add( { type => 'error', text => "string2" } );

is $messages->messages =>
  [ { type => 'error', text => "string1" }, { type => 'error', text => "string2" } ];
