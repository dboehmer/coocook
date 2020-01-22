package Coocook::Script::Role::HasSchema;

use strict;
use warnings;

use Moose::Role;

use Coocook::Schema;

has dsn => (
    is            => 'rw',
    isa           => 'Str',
    default       => 'development',
    documentation => "key in dbic.yaml or DBI DSN string",
);

has _schema => (
    is      => 'rw',
    isa     => 'Coocook::Schema',
    lazy    => 1,
    builder => '_build__schema',
);

sub _build__schema {
    my $self = shift;

    return Coocook::Schema->connect( $self->dsn );
}

1;
