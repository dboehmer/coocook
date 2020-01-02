package Coocook::Script::Users;

# ABSTRACT: script for exporting a list of users

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use feature 'say';
use open OUT => ':locale';    # respect locale setting of STDOUT (terminal)

use Coocook::Schema;
use DateTime;

with 'MooseX::Getopt';

with 'Coocook::Script::Role::HasSchema';

has created => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'limit by date of creation. [+|-]number[d|w|m|y]',
);

has discard => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => "discard selected users (DANGEROUS)",
);

has email_verified => (
    is  => 'rw',
    isa => 'Str',
    documentation =>
      "select users with e-mail address verified (1) or not verified (0), default any ('')",
);

has username => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => "print the username for each user",
);

has display_name => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => "print the display name for each user",
);

has email_address => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => "print the e-mail address for each user",
);

has total => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 1,
    documentation => "print the total number of users",
);

sub run {
    my $self = shift;

    if ( $self->discard ) {
        defined $self->email_verified and $self->email_verified eq '0'
          or die "Option --discard requires --email_verified=0!\n";
    }

    my $users = $self->_schema->resultset('User');

    if ( defined $self->email_verified and length $self->email_verified ) {
        $users =
          $users->search( { email_verified => ( $self->email_verified ? { '!=' => undef } : undef ) } );
    }

    $users = $users->search( $self->_parse_created( $self->created ) );

    if ( $self->display_name or $self->username ) {
        my $total = 0;

        while ( my $user = $users->next ) {
            my $str = '';

            if ( $self->discard ) {
                $user->delete();
                $str .= "discarded ";
            }

            $self->username and $str .= $user->name;

            if ( $self->display_name ) {
                $self->username and $str .= ": ";
                $str .= $user->display_name;
            }

            if ( $self->email_address ) {
                length $str and $str .= " ";
                $str .= "<" . $user->email . ">";
            }

            say $str;
            $total++;
        }

        $self->_print_total($total);
    }
    else {
        $self->_print_total( $users->count );

        $self->discard
          and $users->delete();
    }
}

sub _parse_created {
    my ( $self, $created, $now ) = @_;

    $now = $now ? $now->clone : DateTime->now();

    defined $created
      or return;

    $created =~ / ^ (?<sign>[+-]) (?<number>\d+) (?<unit>[dwmy]) /x
      or die "Invalid value for --created!\n";

    my $op = $+{sign} eq '-' ? '>=' : '<=';    # same logic as -ctime for `find`

    my $unit = {
        d => 'days',
        w => 'weeks',
        m => 'months',
        y => 'years',
    }->{ $+{unit} }
      || die "matched unit not in hash table";

    my $dt = $now->subtract( $unit => $+{number} );

    return { created => { $op => $self->_schema->storage->datetime_parser->format_datetime($dt) } };
}

sub _print_total {
    my ( $self, $total ) = @_;

    $self->total
      and say $total, " ", $total == 1 ? "user" : "users";
}

__PACKAGE__->meta->make_immutable;

1;
