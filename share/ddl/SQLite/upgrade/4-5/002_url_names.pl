use strict;
use warnings;

sub {
    my $schema = shift;

    # important: explicitly select only columns existing in DB schema 5
    my $projects = $schema->resultset('Project')->search( undef, { columns => [qw< id name >] } );

    while ( my $project = $projects->next ) {
        $project->update( { name => $project->name } );    # trigger url_name[_fc]
    }
};
