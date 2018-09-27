use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;

use Test::Most tests => 5;

use_ok 'Coocook::Script::Passwd';

our @stdin;
{
    no warnings qw< once redefine >;
    *Coocook::Script::Passwd::readline = sub { shift @stdin };
}

my $schema = TestDB->new();

my $user = $schema->resultset('User')->first;

sub password_ok {
    my ( $expected, $name ) = @_;

    $user->discard_changes;
    ok $user->check_password($expected), $name || "user accepts password '$expected'";
}

my $app = new_ok 'Coocook::Script::Passwd' => [
    user    => $user->name,
    _schema => $schema,
];

throws_ok {
    local @stdin = qw< one two >;
    $app->run
}
qr/match/, "input passwords don't match";

subtest "change password" => sub {
    password_ok 'P@ssw0rd';

    lives_ok {
        local @stdin = ('s3cr3t') x 2;

        $app->run
    };

    password_ok 's3cr3t';
};

subtest "default username" => sub {
    my $username = $ENV{USER}
      or plan skip_all => '$ENV{USER} not set';

    $user->update( { name => $username } );

    $app = new_ok
      'Coocook::Script::Passwd' => [ _schema => $schema ],
      "create app without explicit username";

    lives_ok {
        local @stdin = ('foobar') x 2;
        $app->run;
    };

    password_ok 'foobar';
};
