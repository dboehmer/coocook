#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Coocook::Script::Users;
Coocook::Script::Users->new_with_options->run;
