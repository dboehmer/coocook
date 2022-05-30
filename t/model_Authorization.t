use Test2::V0;

use Coocook::Model::Authorization;

use lib 't/lib/';
use TestDB;

plan(11);

my $db = TestDB->new;

my ( $project1, $project2 ) = $db->resultset('Project')->all;
my ( $user1,    $user2 )    = $db->resultset('User')->all;

ok my $authz = Coocook::Model::Authorization->new();

sub has_cap_ok   { _test_has_capability( 1, @_ ) }
sub hasnt_cap_ok { _test_has_capability( 0, @_ ) }

sub _test_has_capability {
    my ( $expects_true, $capability, $input, $name ) = @_;

    # +1 from has[nt]_cap_ok wrapper
    local $Test::Builder::Level = $Test::Builder::Level + 2;

    $input->{user} //= undef;    # make sure key is always present

    my ($result) = my @result = $authz->has_capability( $capability, $input );

    ok( ( $result xor !$expects_true ), $name );
    ok( ( @result xor !$expects_true ), "... also in list content" );
}

is $authz->new => $authz, "is a singleton";

is [ $authz->project_roles ] => bag {
    item 'owner';
    item 'admin';
    item 'editor';
    item 'viewer';
},
  "project_roles()";

ok !$authz->capability_exists('foo');
ok $authz->capability_exists('view_project');

is [ sort $authz->capability_needs_input('edit_project') ] => [ 'project', 'user' ];

like dies { $authz->has_capability( foobar => {} ) }, qr/capability/, "invalid capability";

like dies { $authz->has_capability( view_project => {} ) }, qr/missing/, "missing input arguments";

like dies { $authz->has_capability( view_project => { project => $project1 } ) }, qr/missing/,
  "input key 'user' is always required, even if value is optional";

subtest view_project => sub {
    has_cap_ok
      view_project => { project => $project1 },
      "public project";

    hasnt_cap_ok
      view_project => { project => $project2 },
      "private project";

    has_cap_ok
      view_project => { project => $project2, user => $user1 },
      "owner of private project";

    hasnt_cap_ok
      view_project => { project => $project2, user => $user2 },
      "other user for private project";
};

subtest archiving => sub {
    has_cap_ok archive_project => { project => $project1, user => $user1 };
    hasnt_cap_ok unarchive_project => { project => $project1, user => $user1 };

    $project1->archive();

    hasnt_cap_ok archive_project => { project => $project1, user => $user1 };
    has_cap_ok unarchive_project => { project => $project1, user => $user1 };
};
