package Coocook::Model::Messages;

use strict;
use warnings;

use Carp;

my @types = qw<
  debug
  info
  warn
  error
>;

my %types = map { $_ => undef } @types;

for my $type (@types) {
    my $method = sub {
        my $self = shift;

        my %message = @_ == 1 ? ( text => $_[0] ) : @_;

        $message{type} = $type;

        push @$self, \%message;
    };

    no strict 'refs';
    *{ __PACKAGE__ . '::' . $type } = $method;
}

=head1 CONSTRUCTORS

=head2 new

=cut

sub new {
    my $class = shift;

    return bless [], $class;
}

=head1 METHODS

=head2 add(\%message)

=head2 add("$text")

=head2 add(%message)

=cut

sub add {
    my $self = shift;

    my %message = @_ == 1 ? %{ $_[0] } : @_;

    if ( %message == 1 ) {
        my ( $type => $text ) = %message;

        exists $types{$type} or croak "Unsupported type";

        %message = ( type => $type, text => $text );
    }
    else {
        exists $message{type}
          or croak "Argument 'type' required";

        exists $message{text}
          or exists $message{html}
          or croak "Arguments 'text' or 'html' required";
    }

    push @$self, \%message;

    return $self;
}

=head2 clear()

Removes all messages.

=cut

sub clear {
    my $self = shift;
    @$self = ();
    return $self;
}

=head2 messages()

Returns unblessed array reference.

=cut

sub messages { [ @{ $_[0] } ] }

=head2 next()

=cut

sub next { shift @{ $_[0] } }

1;
