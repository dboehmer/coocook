#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Coocook::Script::Cron;
Coocook::Script::Cron->new_with_options->run;
