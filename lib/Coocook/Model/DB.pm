package Coocook::Model::DB;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Catalyst::Model::DBIC::Schema';

### use in-memory SQLite during tests ###

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( $ENV{HARNESS_ACTIVE} ) {
        if ( @_ == 1 ) {
            $_[0]->{connect_info} = "dbi:SQLite::memory:";
        }
        else {
            push @_, ( connect_info => "dbi:SQLite::memory:" );
        }
    }

    return $class->$orig(@_);
};

sub BUILD {
    my $self = shift;

    $ENV{HARNESS_ACTIVE}
      and $self->schema->deploy;
}

######

__PACKAGE__->meta->make_immutable;

__PACKAGE__->config(
    connect_info => {
        sqlite_unicode => 1,
    },
    schema_class => 'Coocook::Schema',
);

1;
