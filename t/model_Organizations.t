use lib 't/lib/';

use TestDB;
use Test::Most;

my $schema = TestDB->new;

use_ok 'Coocook::Model::Organizations';

my $orgs = new_ok 'Coocook::Model::Organizations', [ schema => $schema ];

ok my $org = $orgs->create( name => "FooBar", owner_id => 1 );

isa_ok $org => 'Coocook::Schema::Result::Organization';

is $org->name_fc => 'foobar', "name_fc";

is $orgs->find_by_name('FOOBAR')->id => $org->id;

is $orgs->find_by_name('xyz') => undef;

throws_ok { $orgs->create( name => 'john_doe' ) } qr/name/i, "duplicate with user";
throws_ok { $orgs->create( name => 'foobar' ) } qr/name/i,   "duplicate with organization";

done_testing;
