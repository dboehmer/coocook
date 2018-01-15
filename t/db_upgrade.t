use strict;
use warnings;

use Coocook::Script::Deploy;
use Coocook::Schema;
use Test::Most;

# TODO upgrade fails on Perl 5.26 because .pl file can't be found
# can be fixed by setting PERL_USE_UNSAFE_INC
# wrong assumption of '.' in @INC, probably in DBIx::Class::DeploymentHandler
#
# t/db_upgrade.t .. 1/? Can't locate share/ddl/SQLite/upgrade/4-5/002_url_names.pl
# in @INC (@INC contains: ...) at (eval 1153) line 4.
# at .../site_perl/5.26.0/Context/Preserve.pm line 43.
use lib '.';

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

    ok $dh->upgrade(), $name || "upgrade to version " . $dh->to_version;
}
