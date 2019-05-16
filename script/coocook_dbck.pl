#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Coocook::Script::Dbck;
Coocook::Script::Dbck->new_with_options->run;
