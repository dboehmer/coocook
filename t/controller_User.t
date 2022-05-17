use Test2::V0;

use lib 't/lib';
use Test::Coocook;

my $t = Test::Coocook->new;

$t->get_ok('/user/john_doe');
$t->base_is('https://localhost/login?redirect=%2Fuser%2Fjohn_doe');
$t->robots_flags_ok( { index => 0 } );

$t->login_ok( 'john_doe', 'P@ssw0rd' );
$t->text_contains('Public projects owned by john_doe:');

done_testing();
