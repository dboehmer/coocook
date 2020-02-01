use strict;
use warnings;

use DateTime;
use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Deep;
use Test::Memory::Cycle;
use Test::Most tests => 4;

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
        unassigned_items => 7,
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
      BlacklistEmail
      BlacklistUsername
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

subtest stale => sub {
    my $db = TestDB->new();

    my $rs = $db->resultset('Project');

    is_deeply [ $rs->stale->get_column('id')->all ] => [ 1, 2 ], "ResultSet::Project->stale for today";

    {
        my $date = DateTime->new( year => 2000, month => 1, day => 2 );    # in the middle of project 1

        is_deeply [ $rs->stale($date)->get_column('id')->all ] => [2],
          "ResultSet::Project->stale for $date";

        subtest "Result::Project->is_stale()" => sub {
            ok $rs->find(1)->is_stale();
            ok $rs->find(2)->is_stale();

            ok !$rs->find(1)->is_stale($date);
            ok $rs->find(2)->is_stale($date);
        };
    }
};
