use strict;
use warnings;

use Test2::Require::Module 'Test::PostgreSQL';

use Coocook::Schema;
use Test::Most;

my $pgsql = Test::PostgreSQL->new();

ok my $schema = Coocook::Schema->connect( $pgsql->dsn );

lives_ok { $schema->deploy() } "deploy with DBIC";

done_testing;
