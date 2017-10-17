package TestDB;

use strict;
use warnings;

use parent 'DBICx::TestDatabase';

sub new {
    my $class = shift;

    my $self = $class->SUPER::new( 'Coocook::Schema', @_ );

    open my $fh, '<', 'share/test_data.sql';

    while (<$fh>) {
        $ENV{DBIC_TRACE}
          and warn $_;

        $self->storage->dbh_do( sub { $_[1]->do($_) } );
    }

    close $fh;

    return $self;
}

1;
