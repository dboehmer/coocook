package Coocook::Script::Users;

# ABSTRACT: script for exporting a list of users

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use feature 'say';
use open OUT => ':locale';    # respect locale setting of STDOUT (terminal)

use Coocook::Schema;

with 'MooseX::Getopt';

with 'Coocook::Script::Role::HasSchema';

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

    my $users = $self->_schema->resultset('User');

    if ( defined $self->email_verified and length $self->email_verified ) {
        $users =
          $users->search( { email_verified => ( $self->email_verified ? { '!=' => undef } : undef ) } );
    }

    if ( $self->display_name or $self->username ) {
        my $total = 0;

        while ( my $user = $users->next ) {
            my $str = $self->username ? $user->name : '';

            if ( $self->display_name ) {
                length $str and $str .= ": ";
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
    }
}

sub _print_total {
    my ( $self, $total ) = @_;

    $self->total
      and say $total, " ", $total == 1 ? "user" : "users";
}

__PACKAGE__->meta->make_immutable;

1;
