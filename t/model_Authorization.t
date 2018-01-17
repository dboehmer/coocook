use strict;
use warnings;

use lib 't/lib/';

use Test::Most tests => 7;
use TestDB;

my $db = TestDB->new;

my ( $project1, $project2 ) = $db->resultset('Project')->all;
my ( $user1,    $user2 )    = $db->resultset('User')->all;

use_ok 'Coocook::Model::Authorization';

my $authz = new_ok 'Coocook::Model::Authorization';

is $authz->new => $authz, "is a singleton";

throws_ok { $authz->has_capability( foobar => {} ) } qr/capability/, "invalid capability";

throws_ok { $authz->has_capability( view_project => {} ) } qr/missing/, "missing input arguments";

throws_ok { $authz->has_capability( view_project => { project => $project1 } ) } qr/missing/,
  "input key 'user' is always required, even if value is optional";

sub _test_has_capability {
    my ( $expects_true, $capability, $input, $name ) = @_;

    $input->{user} //= undef;    # make sure key is always present

    ok map( { $expects_true ? $_ : !$_ } $authz->has_capability( $capability, $input ) ), $name
      or explain \@_;
}

sub has_cap_ok   { _test_has_capability( 1, @_ ) }
sub hasnt_cap_ok { _test_has_capability( 0, @_ ) }

subtest view_project => sub {
    has_cap_ok
      view_project => { project => $project1 },
      "public project";

    hasnt_cap_ok
      view_project => { project => $project2 },
      "private project";

    has_cap_ok
      view_project => { project => $project2 },
      "owner of private project";
};