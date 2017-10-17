package Coocook::Model::Importer;

use Carp;
use JSON::MaybeXS;    # also a dependency of Catalyst
use Moose;
use MooseX::NonMoose;

extends 'Catalyst::Model';

__PACKAGE__->meta->make_immutable;

my @internal_properties = (    # array of hashrefs with key 'key' instead of hash to keep order
    {
        key    => 'quantities',
        name   => "Quantities",
        import => sub { shift->quantities },    # quirk: default_unit can't be translated yet
    },
    {
        key        => 'units',
        name       => "Units",
        depends_on => ['quantities'],
        import     => sub { shift->units, { project => 'projects', quantity => 'quantities' } },
    },
    {
        key    => 'shop_sections',
        name   => "Shop Sections",
        import => sub { shift->shop_sections },
    },
    {
        key    => 'articles',
        name   => "Articles",
        import => sub { shift->articles, { project => 'projects', shop_section => 'shop_sections?' } },
    },
    {
        key        => 'articles_units',
        auto       => 1,
        depends_on => [ 'articles', 'units' ],
        import     => sub { shift->articles->articles_units, { article => 'articles', unit => 'units' } },
    },
    {
        key        => 'recipes',
        name       => "Recipes",
        depends_on => [ 'articles', 'units' ],
        import     => [
            sub { shift->recipes },
            sub {
                shift->recipes->ingredients,
                  { project => 'projects', article => 'articles', recipe => 'recipes', unit => 'units' };
            },
        ],
    },
    {
        key    => 'tags',
        name   => "Tags and Tag Groups",
        import => [
            sub { shift->tag_groups },
            sub { shift->tags, { project => 'projects', tag_group => 'tag_groups' } },
        ],
    },
    {
        key        => 'articles_tags',
        auto       => 1,
        depends_on => [ 'articles', 'tags' ],
        import     => sub { shift->articles->article_tags, { article => 'articles', tag => 'tags' } },
    },
    {
        key        => 'recipes_tags',
        auto       => 1,
        depends_on => [ 'recipes', 'tags' ],
        import     => sub { shift->recipes->recipe_tags, { recipe => 'recipes', tag => 'tags' } },
    },
);

my %internal_properties = map { $_->{key} => $_ } @internal_properties;

for my $property (@internal_properties) {
    $property->{name} xor $property->{auto}
      or die "Property $property->{name} can have only 'name' xor 'auto'";

    $property->{$_} ||= [] for qw< depends_on dependency_of >;

    for ( @{ $property->{depends_on} } ) {
        push @{ $internal_properties{$_}{dependency_of} }, $property->{key};
    }
}

my @public_properties = map +{%$_},    # shallow copy
  grep { not $_->{auto} }              # no internal properties
  @internal_properties;

my %public_properties = map { $_->{key} => $_ } @public_properties;

for my $property (@public_properties) {
    delete $property->{import};        # hide from outside world

    # reduce lists to public properties
    for (qw< depends_on dependency_of >) {
        $property->{$_} = [ grep { exists $public_properties{$_} } @{ $property->{$_} } ];
    }
}

sub properties {
    return \@public_properties;
}

my $json;

sub properties_json {
    return $json ||= encode_json( \@public_properties );
}

sub import_data {    # import() is used by 'use'
    my ( $self, $source => $target, $properties ) = @_;

    $self->_validate_properties($properties);

    # simple set
    my %requested_props = map { $_ => 1 } @$properties;

    # map of source-related IDs to target-related IDs
    my %new_id = ( projects => { $source->id => $target->id } );

    $source->result_source->storage->txn_do(
        sub {
            for my $property (@internal_properties) {
                if ( $property->{auto} ) {    # auto: skip if not all dependencies requested
                    grep { not $requested_props{$_} } @{ $property->{depends_on} }
                      and next;
                }
                else {                        # explicitly requested by key
                    $requested_props{ $property->{key} }
                      or next;
                }

                # is this property a dependency of any property that
                # - is requested or
                # - has the 'auto' flag
                my $is_dependency =
                  !!grep { $requested_props{$_} or $internal_properties{$_}{auto} } @{ $property->{dependency_of} };

                # accept coderef or arrayref of coderefs
                my @imports = map { ref eq 'ARRAY' ? @$_ : $_ } $property->{import};

                while ( my $import = shift @imports ) {
                    my ( $rs, $translate ) = $import->($source);
                    my %translate = $translate ? %$translate : ( project => 'projects' );

                    # eliminate optional translations, e.g. shop_section => 'shop_sections?'
                    # 'shop_sections'  => is kept
                    # 'shop_sections?' => 'shop_sections' (if     already translated)
                    # 'shop_sections?' => undef           (if not already translated)
                    for ( values %translate ) {
                        if (s/\?$//) {    # column name had '?' appended, '?' is removed
                            exists $new_id{$_}
                              or $_ = undef;
                        }
                    }

                    # does that table have an 'id' column?
                    my $has_id = exists $rs->result_source->columns_info->{id};

                    my $resultset = $rs->result_source->name;    # e.g. 'projects'

                    # Speeeeeeeed
                    my $hash_rs = $rs->inflate_hashes;

                    # code that is used in both loop variants: update columns of $row following %translate
                    my $translator = sub {
                        my $row = shift;

                        while ( my ( $col => $rs_class ) = each %translate ) {
                            if ( defined $rs_class ) {
                                if ( defined $row->{$col} ) {
                                    $row->{$col} = $new_id{$rs_class}{ $row->{$col} }
                                      || die "new ID of $rs_class $row->{$col} missing for new $resultset";
                                }
                            }
                            else {
                                $row->{$col} = undef;
                            }
                        }
                    };

                    # new ID might be necessary for
                    # - depending properties
                    # - remaining @imports, e.g. first 'tag_groups' then 'tags' with 'tag_group' FK
                    if ( $is_dependency or ( @imports > 0 and $has_id ) ) {    # probably need to store new IDs
                        while ( my $row = $hash_rs->next ) {
                            my $old_id = delete $row->{id};
                            $translator->($row);
                            $new_id{$resultset}{$old_id} = $rs->create($row)->id;
                        }
                    }
                    else {                                                     # IDs don't matter -> go even faster
                        my @buffer;

                        while ( my $row = $hash_rs->next ) {
                            delete $row->{id};
                            $translator->($row);
                            push @buffer, $row;
                        }

                        $rs->populate( \@buffer );                             # must be in void context to save time!
                    }
                }
            }

            # quirk: now update 'default_unit' of new quantities
            my $quantities = $target->quantities->search( { default_unit => { '!=' => undef } },
                { columns => [ 'id', 'default_unit' ] } );

            while ( my $quantity = $quantities->next ) {
                $quantity->update(
                    { default_unit => $new_id{units}{ $quantity->get_column('default_unit') } || die } );
            }
        }
    );

    return 1;
}

sub _validate_properties {
    my ( $self, $property_keys ) = @_;

    ref $property_keys eq 'ARRAY'
      or croak "Expected arrayref of properties";

    my %property_keys = map { $_ => 1 } @$property_keys;

    for my $property_key (@$property_keys) {
        my $property = $public_properties{$property_key}
          or croak "Unknown property: '$property_key'";

        for my $dependency ( @{ $property->{depends_on} } ) {
            $property_keys{$dependency}
              or croak "$property_key requires $dependency";
        }
    }
}

1;
