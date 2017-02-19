package Coocook::Filter::NiceNumber;

use strict;
use warnings;

use parent 'Template::Plugin::Filter';

sub filter {
    my ( $self, $number ) = @_;

    sprintf( '%.3g', $number ) + 0;
}

1;
