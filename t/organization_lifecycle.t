use Test2::V0;

use lib 't/lib';
use Test::Coocook;

my $t = Test::Coocook->new();

$t->get_ok('/');
$t->login_ok( 'john_doe', 'P@ssw0rd' );

$t->follow_link_ok( { text => 'settings Settings' } );
$t->follow_link_ok( { text => 'Organizations' } );
$t->follow_link_ok( { text => 'Test Data' } );

{
    my $org_url = $t->uri;
    $t->submit_form_ok( { form_name => 'delete' } );
    ok $t->get($org_url);
    $t->status_is(404);
}

ok $t->schema->resultset('RoleUser')->search( { user_id => 1, role => $_ } )->delete,
  "revoke '$_' role for user"
  for 'site_owner';

$t->follow_link_ok( { text => 'settings Settings' } );
$t->follow_link_ok( { text => 'Organizations' } );
$t->submit_form_ok(
    {
        with_fields => { name => 'TestOrga' },
        button      => 'create',
    }
);

$t->text_lacks( my $display_name = 'Test Orga' );
$t->submit_form_ok( { with_fields => { display_name => $display_name } } );
$t->text_contains("Organization $display_name");

$t->follow_link_ok( { text => 'Manage memberships' } );

$t->submit_form_ok( { with_fields => { name => 'other', role => 'member' } } );

$t->text_lacks('Transfer ownership');
$t->submit_form_ok( { with_fields => { role => 'admin' } } );

$t->submit_form_ok( { form_name => my $transfer_ownership = 'transfer-ownership' } );

$t->content_lacks($transfer_ownership);

done_testing;
