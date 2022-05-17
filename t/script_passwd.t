use Test2::V0;

our $USER;
BEGIN { $USER = $ENV{USER} ||= 'coocook_test_user' }
use Coocook::Script::Passwd;

use lib 't/lib';
use TestDB;
use Test::Coocook;    # makes Coocook::Script::Passwd not read real config files

plan(4);

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

ok my $app = Coocook::Script::Passwd->new(
    user    => $user->name,
    _schema => $schema,
);

like dies {
    local @stdin = qw< one two >;
    $app->run
} => qr/match/,
  "input passwords don't match";

subtest "change password" => sub {
    password_ok 'P@ssw0rd';

    ok lives {
        local @stdin = ('s3cr3t') x 2;

        $app->run
    };

    password_ok 's3cr3t';
};

subtest "default username" => sub {
    $user->update( { name => $USER } );

    ok $app = Coocook::Script::Passwd->new( _schema => $schema ), "app without explicit username";

    ok lives {
        local @stdin = ('foobar') x 2;
        $app->run;
    }, "run app with same password input twice";

    password_ok 'foobar';
};
