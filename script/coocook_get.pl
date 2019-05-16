#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Coocook::Script::Get;
Coocook::Script::Get->new_with_options->run;
