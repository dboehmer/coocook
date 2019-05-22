use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Most tests => 1;

my $db = TestDB->new();

subtest exists => sub {
    my $rs = $db->resultset('Project');

    _exists( 1,   1 );
    _exists( 999, !1 );

    sub _exists {
        my ( $id, $expects_true, $name ) = @_;

        local $Test::Builder::Level = $Test::Builder::Level + 1;

        my ($result) = my @result = $db->resultset('Project')->search( { id => $id } )->exists;

        ok( ( $result xor !$expects_true ), $name );
        ok( ( @result xor !$expects_true ), "... also in list context" );
    }
};
