package Coocook::Script::Passwd;

# ABSTRACT: script for setting a new password for a user

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use Coocook::Schema;
use Term::ReadKey;

use feature 'fc';    # Perl v5.16

with 'MooseX::Getopt';

with 'Coocook::Script::Role::HasSchema';

has user => (
    accessor      => 'username',
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => "username of a user in the database",
);

if ( my $user = $ENV{USER} ) {
    has '+user' => ( default => $user );
}

has _readline => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub {
        sub { <> }
    },
);

sub run {
    my $self = shift;

    my $user = $self->_schema->resultset('User')->find( { name_fc => fc( $self->username ) } )
      or die "No such user\n";

    my ( $password, $password2 ) = map { $self->readline($_) }
      "Enter new Coocook password: ",
      "Retype new Coocook password: ";

    $password eq $password2
      or die "Sorry, passwords do not match\n";

    $user->update( { password => $password } )
      and printf "Successfully updated password for Coocook user '%s'\n", $user->name;
}

sub readline {
    my ( $self, $prompt ) = @_;

    $prompt and print $prompt;

    Term::ReadKey::ReadMode('noecho');

    my $line = Term::ReadKey::ReadLine(0);

    Term::ReadKey::ReadMode('restore');

    print "\n";

    # for Windows, see https://stackoverflow.com/a/39801196
    $line =~ s/\R\z//;

    return $line;
}

__PACKAGE__->meta->make_immutable;

1;
