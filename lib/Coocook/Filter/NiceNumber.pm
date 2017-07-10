package Coocook::Filter::NiceNumber;

use strict;
use warnings;

use parent 'Template::Plugin::Filter';

use Scalar::Util 'looks_like_number';

sub filter {
    my ( $self, $number ) = @_;

    defined $number or return;
    length $number  or return "";

    looks_like_number($number)
      or die "Argument \"$number\" isn't numeric";

    sprintf( '%.3g', $number ) + 0;
}

1;
