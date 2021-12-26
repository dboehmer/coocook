use Test2::V0;

use lib 't/lib/';
use Test::Coocook;

plan(26);

my $t = Test::Coocook->new( test_data => 0 );

my $user = $t->schema->resultset('User')
  ->create( { map { $_ => '' } qw< name display_name password_hash email_fc > } );

my $project = $user->create_related(
    owned_projects => {
        name        => __FILE__,
        description => __FILE__,
    }
);

my $meal = $project->create_related(
    meals => {
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

$t->get_ok('/badge/dishes_served.svg');
$t->header_like( 'Content-Type' => qr{ ^ image/svg\+xml \b }x );
$t->content_contains('<svg ');
$t->content_contains('</svg>');

sub dish_badge_contains {
    my ( $number, $text ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $dish->update( { servings => $number } );

    $t->get_ok('/badge/dishes_served.svg');
    $t->content_contains( ">$text</text>", "$number => $text" )
      or note $t->content;
}

dish_badge_contains 0 => '0';
dish_badge_contains 1 => '1';

dish_badge_contains 999  => '999';
dish_badge_contains 1000 => '1.0k';

dish_badge_contains 1050 => '1.1k';

dish_badge_contains 999_499 => '999k';
dish_badge_contains 999_500 => '1.0m';

dish_badge_contains 999_499_999 => '999m';
dish_badge_contains 999_500_000 => '1.0b';

dish_badge_contains 1_234_567_890 => '1.2b';

dish_badge_contains 1_000_000_000_000 => '1000b';
