#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Coocook::Schema::DeploymentHandler;
Coocook::Schema::DeploymentHandler->new_with_options->run;
