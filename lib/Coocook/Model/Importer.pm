package Coocook::Model::Importer;

use Carp;
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

sub import_data {    # import() is used by 'use'
    my ( $self, $source => $target, $properties ) = @_;

    $self->_validate_properties($properties);

    # simple set
    my %import = map { $_ => 1 } @$properties;

    # map of source-related IDs to target-related IDs
    my %new_id = ( Project => { $source->id => $target->id } );

    my $_copy_rs = sub {    # anonymous sub to access $source, $target, etc.
        my $rs = shift;
        my $translate = shift || { project => 'Project' };

        my $resultset = $rs->result_source->name;    # e.g. 'Project'

        while ( my $row = $rs->next ) {
            my %new_ids;

            while ( my ( $col => $rs_class ) = each %$translate ) {
                $new_ids{$col} = $new_id{$rs_class}{ $row->get_column($col) }
                  || die "data missing for $rs_class " . $row->get_column($col);
            }

            $new_id{$resultset}{ $row->id } = $row->copy( \%new_ids )->id;
        }
    };

    $import{quantities}    and $_copy_rs->( $source->quantities );
    $import{units}         and $_copy_rs->( $source->units );
    $import{shop_sections} and $_copy_rs->( $source->shop_sections );
    $import{articles}      and $_copy_rs->( $source->articles );

    if ( $import{recipes} ) {
        $_copy_rs->( $source->recipes );
        $_copy_rs->(
            $source->recipes->ingredients,
            { article => 'articles', recipe => 'recipes', unit => 'units' }
        );
    }

    if ( $import{tags} ) {
        $_copy_rs->( $source->tag_groups );
        $_copy_rs->( $source->tags );

        $_copy_rs->( $source->articles->article_tags, { article => 'articles', tag => 'tags' } );
        $_copy_rs->( $source->recipes->recipe_tags,   { recipe  => 'recipes',  tag => 'tags' } );
    }

    return 1;
}

sub _validate_properties {
    my ( $self, $properties ) = @_;

    ref $properties eq 'ARRAY'
      or croak "Expected arrayref of properties";

    my %p = map { $_ => 1 } @$properties;

    for my $p (@$properties) {
        my $property = $properties{$p}
          or croak "Unknown property: '$p'";

        $p{$_} or croak "$p requires $_" for @{ $property->{depends_on} };
    }
}

1;
