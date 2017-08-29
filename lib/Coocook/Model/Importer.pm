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
    {    # TODO make cross tables work implicitly if all dependencies are enabled
        key        => 'articles_units',
        name       => "Articles x Units",
        depends_on => [ 'articles', 'units' ],
        import     => sub { shift->articles->articles_units, { article => 'articles', unit => 'units' } },
    },
    {
        key        => 'recipes',
        name       => "Recipes",
        depends_on => [ 'articles', 'units', 'articles_units' ],
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

    $source->result_source->storage->txn_do(
        sub {
            for my $property (@properties) {
                $requested_props{ $property->{key} } or next;

                # is any property requested that depends on this property?
                my $is_dependency = !!grep { $requested_props{$_} } @{ $property->{dependency_of} };

                # accept coderef or arrayref of coderefs
                my @imports = map { ref eq 'ARRAY' ? @$_ : $_ } $property->{import};

                while ( my $import = shift @imports ) {
                    my ( $rs, $translate ) = $import->($source);
                    $translate ||= { project => 'Project' };

                    # does that table have an 'id' column?
                    my $has_id = exists $rs->result_source->columns_info->{id};

                    my $resultset = $rs->result_source->name;    # e.g. 'Project'

                    # Speeeeeeeed
                    my $hash_rs = $rs->search( undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' } );

                    # if ID exists, might be necessary for depending properties or remaining @imports
                    if ( $is_dependency or @imports and $has_id ) {    # probably need to store new IDs
                        while ( my $row = $hash_rs->next ) {
                            my $old_id = delete $row->{id};

                            while ( my ( $col => $rs_class ) = each %$translate ) {
                                $row->{$col} = $new_id{$rs_class}{ $row->{$col} }
                                  || die "new ID missing for $rs_class $row->{$col}";
                            }

                            $new_id{$resultset}{$old_id} = $rs->create($row)->id;
                        }
                    }
                    else {                                             # IDs don't matter -> go even faster
                        my @buffer;

                        while ( my $row = $hash_rs->next ) {
                            delete $row->{id};

                            while ( my ( $col => $rs_class ) = each %$translate ) {
                                $row->{$col} = $new_id{$rs_class}{ $row->{$col} }
                                  || die "new ID $rs_class $row->{$col} missing for new $resultset";
                            }

                            push @buffer, $row;
                        }

                        $rs->populate( \@buffer );    # must be in void context to save time!
                    }
                }
            }
        }
    );

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
