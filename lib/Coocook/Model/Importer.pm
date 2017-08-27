package Coocook::Model::Importer;

use JSON::MaybeXS;    # also a dependency of Catalyst
use Moose;
use MooseX::NonMoose;

extends 'Catalyst::Model';

__PACKAGE__->meta->make_immutable;

my @properties = (
    {
        key  => 'quantities',
        name => "Quantities",
    },
    {
        key        => 'units',
        name       => "Units",
        depends_on => ['quantities'],
    },
    {
        key  => 'articles',
        name => "Articles",
    },
    {
        key        => 'recipes',
        name       => "Recipes",
        depends_on => [ 'articles', 'units' ],
    },
    {
        key  => 'shop_sections',
        name => "Shop Sections",
    },
    {
        key  => 'tags',
        name => "Tags and Tag Groups",
    },
);

my %properties = map { $_->{key} => $_ } @properties;

for my $property (@properties) {
    $property->{$_} ||= [] for qw< depends_on dependency_of >;

    for ( @{ $property->{depends_on} } ) {
        push @{ $properties{$_}{dependency_of} }, $property->{key};
    }
}

sub properties {
    return \@properties;
}

my $json;

sub properties_json {
    return $json ||= encode_json( \@properties );
}

1;
