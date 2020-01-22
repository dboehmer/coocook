package TestDB;

use strict;
use warnings;

use parent 'DBICx::TestDatabase';

sub new {
    my $class = shift;

    my $schema = $class->next::method( 'Coocook::Schema', @_ );

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

1;
