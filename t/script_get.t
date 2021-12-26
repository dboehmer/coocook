use Test2::V0;

use Coocook::Script::Get;
use Test::Output qw(stdout_from);

use lib 't/lib/';
use TestDB;
use Test::Coocook;    # also makes Coocook::Script::Get not read real config files

plan(5);

Test::Coocook->reload_config( { canonical_url_base => 'https://coocook.example/' } );

my $db = TestDB->new();
Coocook->model('DB')->schema->storage( $db->storage );

like dies { Coocook::Script::Get->new_with_options( ARGV => [] ) }, qr/usage/i,
  "displays usage without arguments";

ok my $app = Coocook::Script::Get->new_with_options( ARGV => ['/internal_server_error'] );

ok my $stdout = stdout_from { $app->run }, "acquire STDOUT";

like $stdout => qr/Oo+ps/, "GET /internal_server_error contains Ooops";

unlike $stdout => qr/internal_server_error/, "HTML contains no references to error page URL";
