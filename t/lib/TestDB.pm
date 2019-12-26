package TestDB;

use strict;
use warnings;

use parent 'DBICx::TestDatabase';

sub new {
    my $class = shift;

    my $schema = $class->next::method( 'Coocook::Schema', @_ );

    open my $fh, '<', 'share/test_data.sql';

    my $continued_line = "";

    while (my $line = <$fh>) {
        chomp $line;
        # Remove comments from SQL-File
        $line =~ s/ -- .* $//x;

        # Remove trailing and leading whitespaces
        $line =~ s/^ \s+ | \s+ $//xg;

        # Skip empty lines
        #chomp();
        length($line) or next;

        # Check if last character of a line is not a semicolon, because in this case
        # the line currently looked at is not a complete SQL-Statement and we can't
        # execute it via DBICx::TestDatabase and first need to add all following lines
        # to our statement until we find a semicolon at the end of a line.
        if ($line !~ m/ ; $ /x) {
            $continued_line = $continued_line." ".$line; 

        } elsif (length($continued_line)) {
            $continued_line = $continued_line." ".$line;
            $schema->storage->dbh_do( sub { $_[1]->do($continued_line) } );

            $ENV{DBIC_TRACE}
              and warn $continued_line;

            $continued_line = "";

        } else {
            $schema->storage->dbh_do( sub { $_[1]->do($line) } );
            $ENV{DBIC_TRACE}
              and warn $line;
        }
    }

    close $fh;

    return $schema;
}

1;
