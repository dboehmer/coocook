use Test2::V0;

use Coocook::Model::Organizations;

use lib 't/lib/';
use TestDB;

my $schema = TestDB->new;

ok my $orgs = Coocook::Model::Organizations->new( schema => $schema );

ok my $org = $orgs->create( name => "FooBar", owner_id => 1 );

isa_ok $org => 'Coocook::Schema::Result::Organization';

is $org->name_fc => 'foobar', "name_fc";

is $orgs->find_by_name('FOOBAR')->id => $org->id;

is $orgs->find_by_name('xyz') => undef;

like dies { $orgs->create( name => 'john_doe' ) } => qr/name/i,
  "duplicate with user";

like dies { $orgs->create( name => 'foobar' ) } => qr/name/i,
  "duplicate with organization";

done_testing;
