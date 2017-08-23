sub {
    use strict;
    use warnings;
    use feature 'fc';

    my $schema = shift;

    my $projects = $schema->resultset('Project');

    while ( my $project = $projects->next ) {
        ( my $url_name = $project->name ) =~ s/\W+/-/g;
        my $url_name_fc = fc $url_name;

        $project->update(
            {
                url_name    => $url_name,
                url_name_fc => $url_name_fc,
            }
        );
    }
};
