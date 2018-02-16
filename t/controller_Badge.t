use strict;
use warnings;

use DBICx::TestDatabase;
use Test::Most;

use Catalyst::Test 'Coocook';

my $schema = DBICx::TestDatabase->new('Coocook::Schema');
Coocook->model('DB')->schema->storage( $schema->storage );

$schema->resultset('User')
  ->create( { map { $_ => '' } qw< name display_name password_hash email > } );

my $meal = $schema->resultset('Meal')->create(
    {
        project => 99999,
        date    => '2000-01-01',
        name    => 'foo',
        comment => '',
    }
);

my $dish = $meal->create_related(
    dishes => {
        name        => 'bar',
        servings    => 0,
        preparation => '',
        description => '',
        comment     => '',
    }
);

sub redirect_is {
    my ( $number, $url ) = @_;

    $dish->update( { servings => $number } );

    my $res = request('https://localhost/badge/dishes_served.svg');
    is $res->code => $_, "is $_ redirect" for 302;
    is $res->header('Location') => $url, "$number => $url";
}

redirect_is 0 => 'https://img.shields.io/badge/dishes_served-0-blue.svg';
redirect_is 1 => 'https://img.shields.io/badge/dishes_served-1-blue.svg';

redirect_is 999  => 'https://img.shields.io/badge/dishes_served-999-blue.svg';
redirect_is 1000 => 'https://img.shields.io/badge/dishes_served-1.0k-blue.svg';

redirect_is 1050 => 'https://img.shields.io/badge/dishes_served-1.1k-blue.svg';

redirect_is 999_499 => 'https://img.shields.io/badge/dishes_served-999k-blue.svg';
redirect_is 999_500 => 'https://img.shields.io/badge/dishes_served-1.0m-blue.svg';

redirect_is 999_499_999 => 'https://img.shields.io/badge/dishes_served-999m-blue.svg';
redirect_is 999_500_000 => 'https://img.shields.io/badge/dishes_served-1.0b-blue.svg';

redirect_is 1_234_567_890 => 'https://img.shields.io/badge/dishes_served-1.2b-blue.svg';

done_testing;
