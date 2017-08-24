use strict;
use warnings;

sub {
    my $schema = shift;

    my $projects = $schema->resultset('Project');

    while ( my $project = $projects->next ) {
        $project->update( { name => $project->name } );    # trigger url_name[_fc]
    }
};
