package Coocook::Model::ProjectImporter;

# ABSTRACT: business logic for importing data to a project from another

use Carp;
use JSON::MaybeXS;    # also a dependency of Catalyst
use Moose;
use MooseX::NonMoose;
use Storable qw(dclone);

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
        import     => sub { shift->units, { project_id => 'projects', quantity_id => 'quantities' } },
    },
    {
        key    => 'shop_sections',
        name   => "Shop Sections",
        import => sub { shift->shop_sections },
    },
    {
        key             => 'articles',
        name            => "Articles",
        soft_depends_on => ['shop_sections'],
        import          =>
          sub { shift->articles, { project_id => 'projects', shop_section_id => 'shop_sections?' } },
    },
    {
        key        => 'articles_units',
        auto       => 1,
        depends_on => [ 'articles', 'units' ],
        import     => sub {
            shift->articles->search_related('articles_units'), { article_id => 'articles', unit_id => 'units' };
        },
    },
    {
        key        => 'recipes',
        name       => "Recipes",
        depends_on => [ 'articles', 'units' ],
        import     => [
            sub { shift->recipes },
            sub {
                shift->recipes->search_related('ingredients'),
                  {
                    project_id => 'projects',
                    article_id => 'articles',
                    recipe_id  => 'recipes',
                    unit_id    => 'units',
                  };
            },
        ],
    },
    {
        key       => 'tags',
        name      => "Tags and Tag Groups",
        conflicts => [ 'tags', 'tag_groups' ],
        import    => [
            sub { shift->tag_groups },
            sub { shift->tags, { project_id => 'projects', tag_group_id => 'tag_groups' } },
        ],
    },
    {
        key        => 'articles_tags',
        auto       => 1,
        depends_on => [ 'articles', 'tags' ],
        import     => sub {
            shift->articles->search_related('articles_tags'), { article_id => 'articles', tag_id => 'tags' };
        },
    },
    {
        key        => 'recipes_tags',
        auto       => 1,
        depends_on => [ 'recipes', 'tags' ],
        import     => sub {
            shift->recipes->search_related('recipes_tags'), { recipe_id => 'recipes', tag_id => 'tags' };
        },
    },
);

my %internal_properties = map { $_->{key} => $_ } @internal_properties;

for my $property (@internal_properties) {
    $property->{name} xor $property->{auto}
      or die "Property $property->{name} can have only 'name' xor 'auto'";

    $property->{auto}
      or $property->{conflicts} ||= [ $property->{key} ];

    $property->{$_} ||= [] for qw< depends_on dependency_of soft_depends_on soft_dependency_of >;

    for ( @{ $property->{depends_on} } ) {
        push @{ $internal_properties{$_}{dependency_of} }, $property->{key};
    }

    for ( @{ $property->{soft_depends_on} } ) {
        push @{ $internal_properties{$_}{soft_dependency_of} }, $property->{key};
    }
}

my @public_properties = map +{%$_},    # shallow copy
  grep { not $_->{auto} }              # no internal properties
  @internal_properties;

my %public_properties = map { $_->{key} => $_ } @public_properties;

for my $property (@public_properties) {
    delete $property->{$_}
      for qw< import soft_depends_on soft_dependency_of >;    # hide internals from outside world

    # reduce lists to public properties
    for (qw< depends_on dependency_of >) {
        $property->{$_} = [ grep { exists $public_properties{$_} } @{ $property->{$_} } ];
    }
}

sub properties {
    return dclone \@public_properties;
}

my $json;

sub properties_json {
    return $json ||= encode_json( \@public_properties );
}

=head2 importable_properties($project, \@properties?)

=head2 unimportable_properties($project, \@properties?)

Returns a list of property hashrefs of all properties that may [not] be imported
into $project because it has no conflicting data.

Properties depending on properties that already have data are also not
importable.

=cut

sub importable_properties   { shift->_importable_properties( 1,  @_ ) }
sub unimportable_properties { shift->_importable_properties( '', @_ ) }

sub _importable_properties {
    my ( $self, $shall_be_importable, $project, $properties ) = @_;

    my $inventory = $project->inventory;    # TODO use cached and/or provide for caching

    my %unimportable;

    # begin with all properties with existing data
  PROPERTY: for my $property ( values %public_properties ) {
        for my $conflict ( @{ $property->{conflicts} } ) {
            if ( $inventory->{$conflict} > 0 ) {
                $unimportable{ $property->{key} } = 1;

                next PROPERTY;
            }
        }
    }

    my @stack = @public_properties{ keys %unimportable };

    # walk dependency tree and mark all depending properties as unimportable
    while ( my $property = shift @stack ) {
        $unimportable{ $property->{key} } = 1;    # TODO done twice for initial @stack

        my $depending = $property->{dependency_of};

        # push those to stack which are not yet indexed
        push @stack, map { $public_properties{$_} || die } grep { not $unimportable{$_} } @$depending;
    }

    my @to_report = $properties ? @public_properties{@$properties} : values %public_properties;

    return grep { !$unimportable{ $_->{key} } eq $shall_be_importable } @to_report;
}

=head2 can_import_properties( $project, \@properties, \@errors?)

Checks that C<@$properties> contains a valid set of properties to import.
Stores relevant error messages in C<@$errors> if given.

=over 4

=item * C<@$properties> must not be empty

=item * each property must be a valid property name

=item * all properties must be importable (see C<importable_properties()>)

=back

=cut

sub can_import_properties {
    my ( $self, $project, $properties, $errors ) = @_;

    $errors ||= [];

    if ( @$properties == 0 ) {
        push @$errors, "No property selected";
        return '';
    }

    my %importable_properties = map { $_->{key} => 1 } $self->importable_properties($project);

    for my $property (@$properties) {
        if ( not exists $public_properties{$property} ) {
            push @$errors, "Not a valid property: '$property'";
            next;
        }

        if ( not $importable_properties{$property} ) {
            push @$errors, "Property can't be imported into project: $property";
        }
    }

    return ( @$errors == 0 );
}

sub import_data {    # import() is used by 'use'
    my ( $self, $source => $target, $properties ) = @_;

    @_ == 4 or croak "import_data() needs 4 arguments";

    $source->id != $target->id
      or croak "source and target project can't be the same";

    $self->_validate_properties($properties);

    {
        my @unimportable = map { $_->{key} } $self->unimportable_properties( $target, $properties );

        @unimportable == 0
          or croak "Cannot import properties because data already exists: " . join ",", @unimportable;
    }

    # simple set
    my %requested_props = map { $_ => 1 } @$properties;

    # map of source-related IDs to target-related IDs
    my %new_id = ( projects => { $source->id => $target->id } );

    $source->txn_do(
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

                # is this property a (soft) dependency of any property that
                # - is requested or
                # - has the 'auto' flag
                my $is_dependency =
                  !!grep { $requested_props{$_} or $internal_properties{$_}{auto} }
                  ( @{ $property->{dependency_of} }, @{ $property->{soft_dependency_of} } );

                # accept coderef or arrayref of coderefs
                my @imports = map { ref eq 'ARRAY' ? @$_ : $_ } $property->{import};

                while ( my $import = shift @imports ) {
                    {
                        my ($target_rs) = $import->($target);

                        $target_rs->results_exist
                          and croak sprintf "target table '%s' not empty", $target_rs->result_source->name;
                    }

                    my ( $rs, $translate ) = $import->($source);
                    my %translate = $translate ? %$translate : ( project_id => 'projects' );

                    # eliminate optional translations, e.g. shop_section_id => 'shop_sections?'
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
                    my $hash_rs = $rs->hri;

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
                    # - remaining @imports, e.g. first 'tag_groups' then 'tags' with 'tag_group_id' FK
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
            my $quantities = $target->quantities->search( { default_unit_id => { '!=' => undef } },
                { columns => [ 'id', 'default_unit_id' ] } );

            if ( $requested_props{units} ) {
                while ( my $quantity = $quantities->next ) {
                    $quantity->update( { default_unit_id => $new_id{units}{ $quantity->default_unit_id } || die } );
                }
            }
            else {
                $quantities->update( { default_unit_id => undef } );
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
