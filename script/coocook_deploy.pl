#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Coocook::Script::Deploy;
Coocook::Script::Deploy->new_with_options->run;
