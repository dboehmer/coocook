package TestDB;

use strict;
use warnings;

use parent 'DBICx::TestDatabase';

use Coocook::Script::Deploy;
use Sub::Exporter -setup => { exports => [qw(install_ok upgrade_ok)] };
use Test::Most;

=head2 CLASS METHODS

=head1 new(...)

Like L<DBICx::TestDatabase> but can initialize database with C<share/test_data.sql>.

=cut

sub new {
    my ( $class, %opts ) = @_;

    my $deploy    = delete $opts{deploy}    // 1;
    my $test_data = delete $opts{test_data} // 1;

    $deploy
      or $opts{nodeploy} = 1;

    my $schema = $class->next::method( 'Coocook::Schema', \%opts );

    ( $deploy and $test_data )
      or return $schema;

    open my $fh, '<', 'share/test_data.sql';

    my $continued_line = "";

    while ( my $line = <$fh> ) {
        chomp $line;

        # Remove comments from SQL-File
        $line =~ s/ -- .* $//x;

        # Remove trailing and leading whitespaces
        $line =~ s/^ \s+ | \s+ $//xg;

        # Skip empty lines
        length($line) or next;

        # All lines get concatenated to $continued_line, only when a semicolon is found
        # at the end of a line $continued_line gets executed and cleared
        length $continued_line
          and $continued_line .= ' ';

        $continued_line .= $line;

        # Only let DBICx::TestDatabase execute the SQL-Statement if it is complete, i.e.
        # there is a semicolon at the end of the line
        if ( $line =~ m/ ; $ /x ) {
            $ENV{DBIC_TRACE}
              and warn "$continued_line\n";

            $schema->storage->dbh_do( sub { $_[1]->do($continued_line) } );

            $continued_line = "";
        }
    }

    close $fh;

    return $schema;
}

=head1 PACKAGE FUNCTIONS

=head2 install_ok( $schema, $version?, $name? )

=cut

sub install_ok {
    my ( $schema, $version, $name ) = @_;

    my $dh = Coocook::Script::Deploy->new( _schema => $schema )->_dh;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $version
      and local *DBIx::Class::DeploymentHandler::to_version = sub { $version };

    ok $dh->install(), $name || "install version " . $dh->to_version;
}

=head2 upgrade_ok( $schema, $version?, $name? )

=cut

sub upgrade_ok {
    my ( $schema, $version, $name ) = @_;

    my $dh = Coocook::Script::Deploy->new( _schema => $schema )->_dh;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $version
      and local *DBIx::Class::DeploymentHandler::to_version = sub { $version };

    ok $dh->upgrade(), $name || "upgrade to version " . $dh->to_version;
}

1;
