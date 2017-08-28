package Coocook::Model::Importer;

use Carp;
use JSON::MaybeXS;    # also a dependency of Catalyst
use Moose;
use MooseX::NonMoose;

extends 'Catalyst::Model';

__PACKAGE__->meta->make_immutable;

my @properties = (
    {
        key    => 'quantities',
        name   => "Quantities",
        import => sub { shift->quantities },
    },
    {
        key        => 'units',
        name       => "Units",
        depends_on => ['quantities'],
        import     => sub { shift->units },
    },
    {
        key    => 'articles',
        name   => "Articles",
        import => sub { shift->articles },
    },
    {
        key        => 'recipes',
        name       => "Recipes",
        depends_on => [ 'articles', 'units' ],
        import     => [
            sub { shift->recipes },
            sub {
                shift->recipes->ingredients, { article => 'articles', recipe => 'recipes', unit => 'units' };
            },
        ],
    },
    {
        key    => 'shop_sections',
        name   => "Shop Sections",
        import => sub { shift->shop_sections },
    },
    {
        key    => 'tags',
        name   => "Tags and Tag Groups",
        import => [
            sub { shift->tag_groups },
            sub { shift->tags },
            sub { shift->articles->article_tags, { article => 'articles', tag => 'tags' } },
            sub { shift->recipes->recipe_tags, { recipe => 'recipes', tag => 'tags' } },
        ],
    },
);

my %properties = map { $_->{key} => $_ } @properties;

for my $property (@properties) {
    $property->{$_} ||= [] for qw< depends_on dependency_of >;

    for ( @{ $property->{depends_on} } ) {
        push @{ $properties{$_}{dependency_of} }, $property->{key};
    }
}

my @public_properties = map +{%$_}, @properties;    # shallow copy
delete $_->{import} for @public_properties;         # hide from outside world

sub properties {
    return \@public_properties;
}

my $json;

sub properties_json {
    return $json ||= encode_json( \@public_properties );
}

sub import_data {                                   # import() is used by 'use'
    my ( $self, $source => $target, $properties ) = @_;

    $self->_validate_properties($properties);

    # simple set
    my %requested_props = map { $_ => 1 } @$properties;

    # map of source-related IDs to target-related IDs
    my %new_id = ( Project => { $source->id => $target->id } );

    for my $property (@properties) {
        $requested_props{ $property->{key} } or next;

        # accept coderef or arrayref of coderefs
        my ($imports) = map { ref eq 'ARRAY' ? $_ : [$_] } $property->{import};

        for my $import (@$imports) {
            my ( $rs, $translate ) = $import->($source);
            $translate ||= { project => 'Project' };

            my $resultset = $rs->result_source->name;    # e.g. 'Project'

            while ( my $row = $rs->next ) {
                my %new_ids;

                while ( my ( $col => $rs_class ) = each %$translate ) {
                    $new_ids{$col} = $new_id{$rs_class}{ $row->get_column($col) }
                      || die "data missing for $rs_class " . $row->get_column($col);
                }

                $new_id{$resultset}{ $row->id } = $row->copy( \%new_ids )->id;
            }
        }
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
