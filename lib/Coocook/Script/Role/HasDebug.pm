package Coocook::Script::Role::HasDebug;

use strict;
use warnings;

use Moose::Role;

has debug => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => "enable debugging output",
);

1;
