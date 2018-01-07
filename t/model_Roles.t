use strict;
use warnings;

use Test::Most tests => 6;

use_ok 'Coocook::Model::Roles';

my $roles = new_ok 'Coocook::Model::Roles';

is $roles => $roles->new, "is a singleton";

ok $roles->role_has_permission( admin => 'make_project_private' ),
  "admin can make projects private";

ok $roles->permission_exists('make_project_private'), "existing permission";
ok !$roles->permission_exists('foobar'), "inexistent permission";
