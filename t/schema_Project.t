use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Most;

subtest articles_cached_units => sub {
    my $db = TestDB->new;

    my $project = $db->resultset('Project')->find(1);

    ok my @result = $project->articles_cached_units, "\$project->articles_cached_units";

    is_deeply [ map ref, @result ] => [ 'ARRAY', 'ARRAY' ], "... returned 2 arrayrefs";

    # delete all entries to make sure everything is cached
    for my $rs (qw< Article Unit >) {
        ok $db->resultset($rs)->delete, "delete all ${rs}s";
        is $db->resultset($rs)->count => 0, "count($rs) == 0";
    }

    # add unit to article to make sure that is cached, too
    $db->resultset('ArticleUnit')->create( { article => 5, unit => 1 } );

    my ( $articles => $units ) = @result;
    my %articles = map { $_->name => $_ } @$articles;

    is join( ",", map { $_->name } @$articles ) => $_,
      "articles are: $_"
      for 'cheese,flour,love,salt,water';

    is join( ",", map { $_->short_name } @$units ) => $_, "units are: $_" for 'g,kg,l,p,t';

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

    is $db->count => 4    # number of records for other projects
      and return;

    note sprintf "% 5i %s", $db->resultset($_)->count, $_ for sort $db->sources;
};

done_testing;
