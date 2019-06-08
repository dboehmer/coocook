use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;

use Test::Most tests => 5;

our $USER = $ENV{USER} ||= 'coocook_test_user';

use_ok 'Coocook::Script::Passwd';

our @stdin;
{
    no warnings qw< once redefine >;
    *Coocook::Script::Passwd::readline = sub { shift @stdin };
}

my $schema = TestDB->new();

my $user = $schema->resultset('User')->one_row;

sub password_ok {
    my ( $password, $name ) = @_;

    $user->discard_changes;
    ok $user->check_password($password), $name || "user accepts password '$password'";
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
    $user->update( { name => $USER } );

    $app = new_ok
      'Coocook::Script::Passwd' => [ _schema => $schema ],
      "app without explicit username";

    lives_ok {
        local @stdin = ('foobar') x 2;
        $app->run;
    }
    "run app with same password input twice";

    password_ok 'foobar';
};
