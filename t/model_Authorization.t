use lib 't/lib/';

use Test::Most tests => 13;
use TestDB;
use Test::Deep;

my $db = TestDB->new;

my ( $project1, $project2 ) = $db->resultset('Project')->all;
my ( $user1,    $user2 )    = $db->resultset('User')->all;

use_ok 'Coocook::Model::Authorization';

my $authz = new_ok 'Coocook::Model::Authorization';

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

cmp_deeply [ $authz->project_roles ] => bag(qw< owner admin editor viewer >),
  "project_roles()";

ok !$authz->capability_exists('foo');
ok $authz->capability_exists('view_project');

is_deeply [ sort $authz->capability_needs_input('view_user') ]    => [];
is_deeply [ sort $authz->capability_needs_input('edit_project') ] => [ 'project', 'user' ];

throws_ok { $authz->has_capability( foobar => {} ) } qr/capability/, "invalid capability";

throws_ok { $authz->has_capability( view_project => {} ) } qr/missing/, "missing input arguments";

throws_ok { $authz->has_capability( view_project => { project => $project1 } ) } qr/missing/,
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
    has_cap_ok archive_project     => { project => $project1, user => $user1 };
    hasnt_cap_ok unarchive_project => { project => $project1, user => $user1 };

    $project1->archive();

    hasnt_cap_ok archive_project => { project => $project1, user => $user1 };
    has_cap_ok unarchive_project => { project => $project1, user => $user1 };
};
