use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestDB;
use Test::Most;

my $db = TestDB->new;

use_ok 'Coocook::Model::Importer';

my $importer = new_ok 'Coocook::Model::Importer';

subtest properties => sub {
    isa_ok my $properties = $importer->properties => 'ARRAY';

    my $depends_on = 0;
    $depends_on += @{ $_->{depends_on} } for @$properties;
    note "found $depends_on 'depends_on'";

    my $dependency_of = 0;
    $dependency_of += @{ $_->{dependency_of} } for @$properties;
    note "found $dependency_of 'dependency_of'";

    cmp_ok $depends_on, '>', 0, "found 'depends_on'";
    is $depends_on => $dependency_of, "depends_on == dependency_of";
};

is substr( $importer->properties_json, 0, 3 ) => '[{"',
  "->properties_json looks like a JSON string";

dies_ok { $importer->import_data() } "import_data() dies without arguments";

my $source = $db->resultset('Project')->find(1);
my $target = $db->resultset('Project')->create( { name => "Import Target" } );

throws_ok { $importer->import_data( $source => $target, {} ) } qr/arrayref/i;
throws_ok { $importer->import_data( $source => $target, ['foobar'] ) } qr/unknown/i;
throws_ok { $importer->import_data( $source => $target, ['recipes'] ) } qr/require|depend/i;

subtest "empty import" => sub {
    my $records_before = $db->count;

    ok $importer->import_data( $source => $target, [] );

    my $records_after = $db->count;
    is $records_before => $records_after, "records before == records after";
};

subtest "complete import" => sub {
    my @not_imported = qw< Dish DishIngredient DishTag Item Meal Project PurchaseList >;
    my %not_imported = map { $_ => 1 } @not_imported;
    my @imported     = grep { not $not_imported{$_} } $db->sources;

    my $records1 = $db->count(@imported);

    my @all = map { $_->{key} } @{ $importer->properties };
    ok $importer->import_data( $source => $target, \@all );

    my $records2 = $db->count(@imported);

    $source->delete();    # delete source project and data

    my $records3 = $db->count(@imported);

    my $deleted  = $records2 - $records3;
    my $imported = $records2 - $records1;

    is $imported => $deleted,
      "rows imported == rows deleted"
      and return;

    note sprintf "% 5i %s", $db->resultset($_)->count, $_ for sort $db->sources;
};

done_testing;
