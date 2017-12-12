use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Memory::Cycle;
use Test::Most;

subtest articles_cached_units => sub {
    my $db = TestDB->new;

    my $project = $db->resultset('Project')->find(1);

    ok my @result = $project->articles_cached_units, "\$project->articles_cached_units";

    is_deeply [ map ref, @result ] => [ 'ARRAY', 'ARRAY' ], "... returned 2 arrayrefs";

    memory_cycle_ok \@result, "... result is free of memory cycles";

    # delete all entries to make sure everything is cached
    $db->resultset('Quantity')->update( { default_unit => undef } );
    for my $rs (qw< DishIngredient Item ArticleTag Article RecipeIngredient Unit >) {
        ok $db->resultset($rs)->delete, "delete all ${rs}s";
        is $db->resultset($rs)->count => 0, "count($rs) == 0";
    }

    # add new unit to new article to make sure that is cached, too
    my $article = $project->create_related( articles => { name => "foo", comment => "" } );
    my $unit = $project->create_related(
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

    ok $db->resultset('Project')->find(1)->delete;

    is $db->count => 7    # number of records for other projects
      and return;

    note sprintf "% 5i %s", $db->resultset($_)->count, $_ for sort $db->sources;
};

done_testing;
