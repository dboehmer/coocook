use Test2::V0;

use Coocook::Model::ProjectImporter;
use Scalar::Util qw(refaddr);

use lib 't/lib';
use TestDB;

plan(15);

my $db = TestDB->new;

ok my $importer = Coocook::Model::ProjectImporter->new();

# TODO this is probably implemented better somewhere on CPAN
#      but I couldn't find it, even asked #perl-help on IRC
sub _no_shared_references {
    my ( $a, $b, $name ) = @_;

    my ( %a, %b );

    # collect reference addresses
    for ( [ $a => \%a ], [ $b => \%b ] ) {
        my ( $root, $hash ) = @$_;

        my @stack = ($root);

        while (@stack) {
            my $value = pop @stack;
            my $addr  = refaddr($value) || next;

            # already seen
            exists $hash->{$addr} and next;

            $hash->{$addr} = undef;    # undef is most efficient value

            my $type = ref $value;

            if    ( $type eq 'ARRAY' ) { push @stack, @$value }
            elsif ( $type eq 'HASH' )  { push @stack, values %$value }
            else                       { die "Unsupported reference type '$type'" }
        }
    }

    # find duplicates
    my @duplicates = grep { exists $a{$_} } keys %b;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    cmp_ok @duplicates, '==', 0, $name || "data structures share not references";
}

subtest properties => sub {
    is my $properties = $importer->properties => array { etc };

    my $depends_on = 0;
    $depends_on += @{ $_->{depends_on} } for @$properties;
    note "found $depends_on 'depends_on'";

    my $dependency_of = 0;
    $dependency_of += @{ $_->{dependency_of} } for @$properties;
    note "found $dependency_of 'dependency_of'";

    cmp_ok $depends_on, '>', 0, "found 'depends_on'";
    is $depends_on => $dependency_of, "depends_on == dependency_of";

    my %properties = map { $_->{key} => $_ } @$properties;

    is $properties{tags}{conflicts} => [ 'tags', 'tag_groups' ],
      "properties.tags.conflicts = [ tags, tag_groups ] like defined in Importer.pm";

    is $properties{units}{conflicts} => ['units'],
      "properties.units.conflicts = [ units ] per default";

    # properties data structure should be safe to modify
    ok my $properties2 = $importer->properties;
    _no_shared_references $properties, $properties2;
};

is substr( $importer->properties_json, 0, 3 ) => '[{"',
  "->properties_json looks like a JSON string";

my $source = $db->resultset('Project')->find(1);
my $target = $db->resultset('Project')->create(
    {
        name        => "Import Target",
        description => "",
        owner_id    => 1,
    }
);

subtest can_import_properties => sub {
    my $errors = [];
    ok !$importer->can_import_properties( $target, [], $errors );
    like $errors => [qr/no property/i];

    $errors = [];
    ok !$importer->can_import_properties( $target, ['foobar'], $errors );
    like $errors => [qr/( not .+ valid | invalid ) .+ property .+ foobar/ix];

    $errors = [];
    ok !$importer->can_import_properties( $source, ['units'], $errors );
    like $errors => [qr/ property .+ ( can't .+ import | unimportable ) .+ units/ix];

    $errors = [];
    ok $importer->can_import_properties( $target, [ 'quantities', 'units' ], $errors );
    like $errors => [];
};

subtest "[un]importable_properties" => sub {
    my @source_importable = map { $_->{key} } $importer->importable_properties($source);
    is \@source_importable => [],
      "importable(source project)";

    my @source_unimportable = map { $_->{key} } $importer->unimportable_properties($source);

    is \@source_unimportable =>
      bag { item $_ for qw< articles quantities recipes shop_sections tags units > },
      "unimportable(source project)";

    @source_unimportable =
      map { $_->{key} } $importer->unimportable_properties( $source, ['quantities'] );
    is \@source_unimportable => ['quantities'],
      "unimportable(source project, [quantities])";

    my @target_importable = map { $_->{key} } $importer->importable_properties($target);
    is \@target_importable =>
      bag { item $_ for qw< articles quantities recipes shop_sections tags units > },
      "importable(target project)";

    ok my $quantity = $target->quantities->create( { name => 'foo' } ), "create a quantity in target";

    my @target_importable2 = map { $_->{key} } $importer->importable_properties($target);

    is \@target_importable2 => bag { item $_ for qw< articles shop_sections tags > },
      "importable(target project)";

    ok $quantity->delete(), "delete quantity";
};

like dies { $importer->import_data() } => qr/argument/, "import_data() dies without arguments";

like dies { $importer->import_data( $source => $source, [] ) } => qr/same/,
  "import_data() dies with source == target";

like dies { $importer->import_data( $target => $source, ['quantities'] ) } =>
  qr/ import .+ quantities /x,
  "import_data() dies if target already has data";

like dies { $importer->import_data( $source => $target, {} ) }          => qr/arrayref/i;
like dies { $importer->import_data( $source => $target, ['foobar'] ) }  => qr/unknown/i;
like dies { $importer->import_data( $source => $target, ['recipes'] ) } => qr/require|depend/i;
like dies {
    $importer->import_data( $source => $target, [qw< quantities units articles articles_units >] )
} => qr/unknown/i,
  "private properties are rejected";

subtest "empty import" => sub {
    my $records_before = $db->count;

    ok $importer->import_data( $source => $target, [] );

    my $records_after = $db->count;
    is $records_before => $records_after, "records before == records after";
};

subtest "complete import" => sub {
    my @not_imported =
      qw< Dish DishIngredient DishTag Item Meal Project ProjectUser PurchaseList User >;
    my %not_imported = map  { $_ => 1 } @not_imported;
    my @imported     = grep { not $not_imported{$_} } $db->sources;

    my $records1 = $db->count(@imported);

    my @all = map { $_->{key} } @{ $importer->properties };
    ok $importer->import_data( $source => $target, \@all );

    my $records2 = $db->count(@imported);

    $source->delete();    # delete source project and data

    my $records3 = $db->count(@imported);

    my $deleted  = $records2 - $records3;
    my $imported = $records2 - $records1;

    # was broken in ccd0b94
    is $target->articles->find( { name => 'flour' } )->shop_section->name => 'bakery products',
      "article 'flour' stays in shop section 'bakery products'";

    is $imported => $deleted,
      "rows imported == rows deleted"
      and return;

    note sprintf "% 5i %s", $db->resultset($_)->count, $_ for sort $db->sources;
};

like dies { $importer->import_data( $source, $target, ['quantities'] ) } =>
  qr/already .+ exist .+ quantities/x,
  "repeated import is rejected";
