#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use TestDB;
use Test::Coocook;
use Test::Most tests => 2;

our $SCHEMA = TestDB->new();

my $t = Test::Coocook->new( max_redirect => 0 );

subtest "HTTP redirects to HTTPS" => sub {
    $t->get('http://localhost/');
    $t->status_is(302);
    $t->header_is( Location => 'https://localhost/' );
};

$t->get_ok('https://localhost');
