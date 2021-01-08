use lib 't/lib/';

use TestDB;
use Test::Most tests => 1;

my $db = TestDB->new;

subtest make_owner => sub {
    my $project = $db->resultset('Project')->find(1);

    my $editor = $project->projects_users->search( { role => 'editor' } )->one_row
      || die "missing test data";

    throws_ok { $editor->make_owner } qr/admin/, "making an editor to an owner fails";

    $editor->update( { role => 'admin' } );
    my $admin = $editor;

    ok $admin->make_owner, "making an admin to an owner works";

    $admin->discard_changes;
    is $admin->role => 'owner',
      "... updated 'role' column of projects_users";

    is $admin->project->owner_id => $editor->user_id,
      "... updated column 'owner_id' of project";

    my $owner = $admin;

    warning_like { $owner->make_owner } qr/already/, "warns when making an owner to an owner";
};
