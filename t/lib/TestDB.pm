package TestDB;

use strict;
use warnings;

use parent 'DBICx::TestDatabase';

sub new {
    my $class = shift;

    my $schema = $class->next::method( 'Coocook::Schema', @_ );

    open my $fh, '<', 'share/test_data.sql';

    my $continued_line = "";
    my $last_line_was_continued = 0;

    while (<$fh>) {
        $ENV{DBIC_TRACE}
          and warn $_;
	my $line = $_;

	# Remove comments from SQL-File
	my $comment_start = index ($line, '--');
	$line = substr ($line, 0, $comment_start);
    # Remove trailing and leading whitespaces
    $line =~ s/^\s+|\s+$//g;
	next if $line =~ /^\s*$/;
	my $last_character = substr ($line, -1);

	# Check if last character of a line is not a semicolon, because in this case
	# the line currently looked at is not a complete SQL-Statement and we can't
	# execute it via DBICx::TestDatabase and first need to add all following lines
	# to our statement until we find a semicolon at the end of a line.
	if ($last_character ne ';') {
	    $continued_line = $continued_line." ".$line; 
	    $last_line_was_continued = 1;
	} elsif ($last_line_was_continued) {
	    $continued_line = $continued_line." ".$line;
	    $schema->storage->dbh_do( sub { $_[1]->do($continued_line) } );
	    $continued_line = "";
	    $last_line_was_continued = 0;
	} else {
	    $schema->storage->dbh_do( sub { $_[1]->do($line) } );
	}
    }

    close $fh;

    return $schema;
}

1;
