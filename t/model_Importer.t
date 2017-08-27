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

subtest import_data => sub {
    dies_ok { $importer->import_data() } "dies without arguments";

    my $source = $db->resultset('Project')->find(1);
    my $target = $db->resultset('Project')->create( { name => "Import Target" } );

    throws_ok { $importer->import_data( $source => $target, {} ) } qr/arrayref/i;
    throws_ok { $importer->import_data( $source => $target, ['foobar'] ) } qr/unknown/i;
    throws_ok { $importer->import_data( $source => $target, ['recipes'] ) } qr/require|depend/i;

    my @all = map { $_->{key} } @{ $importer->properties };
    ok $importer->import_data( $source => $target, \@all );

    my %related = (
        articles           => sub { shift->articles },
        articles_tags      => sub { shift->articles->tags },
        quantities         => sub { shift->quantities },
        recipes            => sub { shift->recipes },
        recipe_ingredients => sub { shift->recipes->ingredients },
        recipe_tags        => sub { shift->recipes->tags },
        shop_sections      => sub { shift->shop_sections },
        tags               => sub { shift->tags },
        tag_groups         => sub { shift->tag_groups },
        units              => sub { shift->units },
    );

    for my $related ( sort keys %related ) {
        my $count = $related{$related}->($source)->count;
        is $related{$related}->($target) => $count, "created $count $related";
    }
};

done_testing;
