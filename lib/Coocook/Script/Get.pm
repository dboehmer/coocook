package Coocook::Script::Get;

# ABSTRACT: script to print the response body to a GET request

use Moose;
use Catalyst::Test 'Coocook';    # Catalyst::Test is part of Catalyst-Runtime
use URI;

has ARGV => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { \@ARGV },
);

has path => (
    is  => 'rw',
    isa => 'Str',
);

# implement interface of MooseX::GetOpt and MooseX::App
# but MooseX::App is no dependency of Coocook as of 2018
# and MooseX::GetOpt doesn't support positional parameters
sub new_with_options {
    my $class = shift;

    my $self = $class->new(@_);

    my $argv = $self->ARGV;

    @$argv == 1
      or die "Usage: $0 URI_PATH\n";

    $self->path( $argv->[0] );

    return $self;
}

sub run {
    my $self = shift;

    my $uri = URI->new( $self->path );
    $uri->scheme('https');    # HTTPS is required

    print get($uri);
}

1;
