use strict;
use warnings;

use Test::PerlTidy;

run_tests(
    exclude => [
        qr{ ^\.build/ }x,                 # Dist::Zilla build directory
        qr{ ^blib/ }x,                    # build directory
        qr{ ^Coocook- \d+ \. \d+ / }x,    # Dist::Zilla output directories
    ]
);
