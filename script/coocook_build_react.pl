#!/usr/bin/env perl

# ABSTRACT: script for building the react components for the coocook frontend

use v5.28;
use utf8;
use warnings;
use strict;

use Term::ANSIColor;
use Cwd qw/abs_path getcwd/;
use File::Copy::Recursive qw(rcopy);
use File::Path 'rmtree';

say colored('START BUILD COOCOOK REACT COMPONENTS...', 'yellow');

say colored('CHECK IF AT TOP-LEVEL OF COOCOOK REPOSITORY...', 'yellow');
my $dir = abs_path(getcwd());
if (not ($dir =~ /^.*\/coocook$/)) {
    error('This script can only be executed in the top-level coocook repository');
}
say colored('CURRENT DIRECTORY IS TOP-LEVEL OF COOCOOK REPOSITORY', 'green');

chdir('share/coocook-react-components') or error("Directory 'share/coocook-react-components' does not exist");

say colored('RUN NPM BUILD...', 'yellow');
system('npm', 'run', 'build') == 0 or error("Failed NPM build");
chdir('../..');
say colored('NPM BUILD DONE.', 'green');

say colored('DELETE OLD BUILD OF INGREDIENTS EDITOR...', 'yellow');
rmtree('root/static/lib/ingredients_editor') or error("Failed removing 'root/static/lib/ingredients_editor'");
say colored('DELETE DONE.', 'green');

say colored('COPY NEW BUILD OF INGREDIENTS EDITOR...', 'yellow');
rcopy('share/coocook-react-components/build', 'root/static/lib/ingredients_editor') or error("Failed at copying the new build");
say colored('COPY DONE.', 'green');

say colored('BUILD COOCOOK REACT COMPONENTS DONE.', 'green');

sub error {
    my $msg = shift;
    say '';
    say colored($msg, 'red');
    exit 1;
}
