package Coocook::Model::RecipeImporter;

# ABSTRACT: business logic for importing a recipe into a different project

use Moose;
use Carp;

has project => (
    is       => 'rw',
    isa      => 'Coocook::Schema::Result::Project',
    required => 1,
);

has recipe => (
    is       => 'rw',
    isa      => 'Coocook::Schema::Result::Recipe',
    required => 1,
);

has ingredients => (
    is      => 'rw',
    isa     => 'ArrayRef[HashRef]',
    lazy    => 1,
    builder => '_build_ingredients',
);

for ( 'source', 'target' ) {
    has "${_}_articles" => (
        is      => 'rw',
        isa     => 'ArrayRef[HashRef]',
        lazy    => 1,
        builder => "_build_${_}_articles",
    );

    has "${_}_units" => (
        is      => 'rw',
        isa     => 'ArrayRef[HashRef]',
        lazy    => 1,
        builder => "_build_${_}_units",
    );
}

__PACKAGE__->meta->make_immutable;

sub _build_ingredients { return [ shift->recipe->ingredients_sorted->hri->all ] }

sub _build_source_articles {
    return [
        shift->recipe->ingredients->search_related( 'article', undef, { distinct => 1 } )->hri->all
    ];
}

sub _build_source_units {
    return [ shift->recipe->ingredients->search_related( 'unit', undef, { distinct => 1 } )->hri->all ];
}

sub _build_target_articles {
    return [ shift->project->articles->search( undef, { order_by => 'name' } )->hri->all ];
}

sub _build_target_units {
    return [
        shift->project->units->search( undef, { order_by => [ 'long_name', 'short_name' ] } )->hri->all
    ];
}

sub BUILD {
    my $self = shift;

    # link IDs in ingredients to source_(article|unit) hashrefs
    my %articles = map { $_->{id} => $_ } @{ $self->source_articles };
    my %units    = map { $_->{id} => $_ } @{ $self->source_units };

    for my $ingredient ( @{ $self->ingredients } ) {
        $_ = $articles{$_} for $ingredient->{article};
        $_ = $units{$_}    for $ingredient->{unit};
    }
}

sub identify_candidates {
    my $self = shift;

    my %rels = (
        articles => ['name'],
        units    => [ 'long_name', 'short_name' ],
    );

    while ( my ( $rel => $keys ) = each %rels ) {
        my $target_method = "target_${rel}";
        my $target_rows   = $self->$target_method();
        my %target_rows;

        # index @$target_rows by all @$keys
        for my $key (@$keys) {
            push @{ $target_rows{$key}{ $_->{$key} } }, $_ for @$target_rows;
        }

        my $source_method = "source_${rel}";
        my $source_rows   = $self->$source_method();

      ROW: for my $source_row (@$source_rows) {
          KEY: for my $key (@$keys) {
                my $candidates = $target_rows{$key}{ $source_row->{$key} }
                  or next KEY;

                # candidate is plausible if 1 row matched
                if ( @$candidates == 1 ) {
                    my $row = $source_row->{target_candidate} = $candidates->[0];
                    next ROW;
                }
            }

            # ensure hash key exists
            $source_row->{target_candidate} = undef;
        }
    }

    return $self;
}

sub import_data {    # import() used by 'use'
    my ( $self, %args ) = @_;

    my %ingredients = %{ $args{ingredients} };    # shallow copy

    my %articles = map { $_->{id} => $_ } @{ $self->target_articles };
    my %units    = map { $_->{id} => $_ } @{ $self->target_units };

    my $articles_units_rs = $self->project->result_source->schema->resultset('ArticleUnit');
    my $ingredients_rs    = $self->recipe->ingredients;

    return $self->project->txn_do(
        sub {
            my $recipe = $self->project->recipes->create(    # $self->recipe->copy() would do CASCADE COPY
                {
                    project     => $self->project->id,
                    preparation => $self->recipe->preparation,
                    description => $self->recipe->description,
                    name        => $args{name} || $self->recipe->name,
                    servings    => $args{servings} || $self->recipe->servings,
                }
            );

            for my $ingredient ( @{ $self->ingredients } ) {
                my $ingredient_id = $ingredient->{id};

                my $mapping = delete $ingredients{$ingredient_id}
                  or croak "missing mapping for ingredient $ingredient_id";

                $mapping->{skip}
                  and next;

                my $unit    = $units{ $mapping->{unit} }       || croak "invalid unit " . $mapping->{unit};
                my $article = $articles{ $mapping->{article} } || croak "invalid article " . $mapping->{article};
                my $comment = $mapping->{comment} // $ingredient->{comment};
                my $value   = $mapping->{value}   // $ingredient->{value};

                $articles_units_rs->exists( { article => $article->{id}, unit => $unit->{id} } )
                  or croak "invalid combination of article and unit";

                $ingredients_rs->find($ingredient_id)->copy(
                    {
                        recipe  => $recipe->id,
                        article => $article->{id},
                        unit    => $unit->{id},
                        value   => $value,
                        comment => $comment,
                    }
                );
            }

            return $recipe;
        }
    );
}

1;
