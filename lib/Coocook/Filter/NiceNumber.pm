package Coocook::Filter::NiceNumber;

use strict;
use warnings;

use parent 'Template::Plugin::Filter';

use Scalar::Util 'looks_like_number';

sub filter {
    my ( $self, $number ) = @_;

    defined $number or return;
    length $number  or return "";

    $number =~ s/,/./g;    # workaround for German number format
    looks_like_number($number)
      or die "Argument \"$number\" isn't numeric";

    # TODO how to round to 3 significant digits while keeping decimal notation?

    # use 3 significant digits and format in decimal notation again
    my $str = sprintf '%f', sprintf '%.3g', $number;

    # trim trailing zeros after dot
    $str =~ s/
      (
        \.        # dot
        [0-9]*    # maybe some digits
        [1-9]     # last relevant digit
        \K        # don't include left part in match
      |       # OR
        \.        # dot directly before
      )
      0+          # only zeros anymore
      $
    //x;

    return $str;
}

1;
