package Coocook::Script::Cron;

# ABSTRACT: script to be executed regularly by cron for routine tasks

use open ':locale';
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

with 'Coocook::Script::Role::HasDebug';
with 'Coocook::Script::Role::HasSchema';
with 'MooseX::Getopt';

has delta_days => (
    is            => 'rw',
    isa           => 'Int',
    default       => 7,
    documentation => "Number of days to keep expired sessions (default: 1 week)",
);

my $DAY_SECS = 60 * 60 * 24;

sub run {
    my $self = shift;

    my $sessions = $self->_schema->resultset('Session');
    my $expired  = $sessions->search( { expires => { '<' => time - $DAY_SECS * $self->delta_days } } );

    my $rows = $self->debug ? $expired->count : undef;

    $expired->delete();

    defined $rows
      and printf "Deleted %i expired sessions\n", $rows;
}

__PACKAGE__->meta->make_immutable;

1;
