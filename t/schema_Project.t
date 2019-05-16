use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Memory::Cycle;
use Test::Most tests => 3;

subtest inventory => sub {
    my $db = TestDB->new();

    my $inventory = $db->resultset('Project')->find(1)->inventory();

    is_deeply $inventory => {
        articles         => 5,
        dishes           => 3,
        meals            => 3,
        purchase_lists   => 1,
        quantities       => 2,
        recipes          => 1,
        shop_sections    => 2,
        tags             => 3,
        units            => 5,
        unassigned_items => 6,
      }
      or explain $inventory;
};

subtest articles_cached_units => sub {
    my $db = TestDB->new;

    my $project = $db->resultset('Project')->find(1);

    ok my @result = $project->articles_cached_units, "\$project->articles_cached_units";

    is_deeply [ map ref, @result ] => [ 'ARRAY', 'ARRAY' ], "... returned 2 arrayrefs";

    memory_cycle_ok \@result, "... result is free of memory cycles";

    # delete all entries to make sure everything is cached
    $db->resultset('Quantity')->update( { default_unit => undef } );
    for my $rs (qw< DishIngredient Item ArticleTag RecipeIngredient Article Unit >) {
        ok $db->resultset($rs)->delete, "delete all ${rs}s";
        is $db->resultset($rs)->count => 0, "count($rs) == 0";
    }

    # add new unit to new article to make sure that is cached, too
    my $article = $project->create_related( articles => { name => "foo", comment => "" } );
    my $unit    = $project->create_related(
        units => { short_name => "b", long_name => "bar", quantity => 1, space => 0 } );
    $article->add_to_units($unit);

    my ( $articles => $units ) = @result;
    my %articles = map { $_->name => $_ } @$articles;

    is join( ",", map { $_->name } @$articles ) => $_,
      "articles are: $_"
      for 'cheese,flour,love,salt,water';

    is join( ",", map { $_->short_name } @$units ) => $_, "units are: $_" for 'g,kg,l';

    my %articles_units = (
        cheese => 'g,kg',
        flour  => 'g,kg',
        love   => '',
        salt   => 'g',
        water  => 'l',
    );

    for my $article ( sort keys %articles_units ) {
        is join( ',', map { $_->short_name } $articles{$article}->units ) => $articles_units{$article},
          "$article has units ($articles_units{$article})";
    }
};

subtest delete => sub {
    my $db = TestDB->new;

    $db->enable_fk_checks();

    my @projects = $db->resultset('Project')->all
      or die "no projects";

    for my $project (@projects) {
        ok $project->delete(), "delete project " . $project->name;
    }

    my %unaffected_sources = map { $_ => 1 } qw<
      FAQ
      RoleUser
      Terms
      User
    >;

    for my $source ( $db->sources ) {
        $unaffected_sources{$source}
          or is $db->resultset($source)->count => 0,
          "table $source has zero rows";
    }
};
