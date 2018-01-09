use strict;
use warnings;

use Test::Most tests => 8;

use_ok 'Coocook::Model::Roles';

my $roles = new_ok 'Coocook::Model::Roles';

is $roles => $roles->new, "is a singleton";

ok $roles->role_has_permission( admin => 'make_project_private' ),
  "admin can make projects private";

ok $roles->permission_exists('make_project_private'), "existing permission";
ok !$roles->permission_exists('foobar'), "inexistent permission";

isa_ok scalar $roles->roles_with_permission('make_project_private') => 'ARRAY',
  "roles_with_permission() returns arrayref in scalar context";

is_deeply [ sort $roles->roles_with_permission('make_project_private') ] =>
  [ 'admin', 'private_projects' ],
  "roles_with_permission()";
