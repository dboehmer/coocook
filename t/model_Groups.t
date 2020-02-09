use strict;
use warnings;

use lib 't/lib/';

use TestDB;
use Test::Most;

my $schema = TestDB->new;

use_ok 'Coocook::Model::Groups';

my $groups = new_ok 'Coocook::Model::Groups', [ schema => $schema ];

ok my $group = $groups->create( name => "FooBar", owner => 1 );

isa_ok $group => 'Coocook::Schema::Result::Group';

is $group->name_fc => 'foobar', "name_fc";

is $groups->find_by_name('FOOBAR')->id => $group->id;

is $groups->find_by_name('xyz') => undef;

throws_ok { $groups->create( name => 'john_doe' ) } qr/name/i, "duplicate with user";
throws_ok { $groups->create( name => 'foobar' ) } qr/name/i,   "duplicate with group";

done_testing;
