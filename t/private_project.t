use Test2::V0;

use lib 't/lib';
use Test::Coocook;

my $t = Test::Coocook->new();

my $project = $t->schema->resultset('Project')->find(1);

my $username = $project->owner->name;

$t->get('/');
$t->login_ok( 'john_doe', 'P@ssw0rd' );

$t->get_ok("/user/$username");
$t->text_contains( $project->name );

ok $project->update( { is_public => '' } ), "make project private";

$t->get_ok("/user/$username");
$t->text_lacks( $project->name );

done_testing;
