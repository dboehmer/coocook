use strict;
use warnings;

use Coocook::Script::Deploy;
use Coocook::Schema;
use Test::Most;

my $schema = Coocook::Schema->connect('dbi:SQLite::memory:');

my $app = Coocook::Script::Deploy->new( _schema => $schema );

my $dh = $app->_dh;

install_ok(1);
upgrade_ok();    # newest version

done_testing;

sub install_ok {
    my ( $version, $name ) = @_;

    $version
      and local *DBIx::Class::DeploymentHandler::to_version = sub { $version };

    ok $dh->install(), $name || "install version " . $dh->to_version;
}

sub upgrade_ok {
    my ( $version, $name ) = @_;

    $version
      and local *DBIx::Class::DeploymentHandler::to_version = sub { $version };

    ok $dh->upgrade(), $name || "upgrade to version" . $dh->to_version;
}
