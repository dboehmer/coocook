use strict;
use warnings;

sub {
    my $schema = shift;

    # important: explicitly select only columns existing in DB schema 8
    my $users = $schema->resultset('User')->search( undef, { columns => [qw< id name >] } );

    while ( my $user = $users->next ) {
        $user->update( { name => $user->name } );    # trigger name_fc
    }
};
