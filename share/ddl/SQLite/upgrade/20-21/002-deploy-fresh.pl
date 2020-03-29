use strict;
use warnings;

use DBIx::Class::DeploymentHandler;

sub {
    my $schema   = shift;
    my $versions = shift;

    my ( $from_version => $to_version ) = @$versions;

    my $dh = DBIx::Class::DeploymentHandler->new(
        {
            schema           => $schema,
            databases        => 'SQLite',
            script_directory => 'share/ddl',
        }
    );

    $dh->deploy( { version => $to_version } );
};
