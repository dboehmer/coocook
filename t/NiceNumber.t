#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use_ok 'Coocook::Filter::NiceNumber';

my $filter = new_ok 'Coocook::Filter::NiceNumber';

isa_ok $filter, 'Template::Plugin::Filter';

# 3 significant digits
t( 123        => "123" );
t( 1.23       => "1.23" );
t( 1.234567   => "1.23" );
t( 12345.6789 => "12300" );
t( 1 / 3      => "0.333" );
t( 0.999999   => "1" );
t( 123456789  => "123000000" );

done_testing;

sub t {
    my ( $input, $expected, $name ) = @_;

    my $output = $filter->filter($input);

    cmp_ok $output => eq => $expected, $name || "$input eq '$expected'";
}
