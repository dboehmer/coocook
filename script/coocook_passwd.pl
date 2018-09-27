#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Coocook::Script::Passwd;
Coocook::Script::Passwd->new_with_options->run;
