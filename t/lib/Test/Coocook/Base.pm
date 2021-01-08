package Test::Coocook::Base;

use strict;
use warnings;

use Import::Into;
use Test2::Plugin::UTF8;

=encoding utf8

=head1 SYNOPSIS

    use lib 't/lib';
    use Test::Coocook::Base;

    print "Beste Grüße!\n";

Automatically sets some common pragmas in the test file:

    use strict;
    use warnings;
    use open ':locale';    # respect encoding configured in terminal
    use utf8;              # read test file as UTF-8

=cut

sub import {
    my $class  = shift;
    my $caller = caller;

    strict->import::into($caller);
    warnings->import::into($caller);
    'open'->import::into( $caller, ':locale' );
    utf8->import::into($caller);
}

1;
