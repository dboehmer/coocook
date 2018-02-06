package Coocook::Model::PurchaseList;

# ABSTRACT: business logic for plain data structure of purchase list

use Moose;
use Scalar::Util 'weaken';

has list => (
    is       => 'ro',
    isa      => 'Coocook::Schema::Result::PurchaseList',
    required => 1,
);

has shop_sections => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has units => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

sub BUILD {
    my $self = shift;

    my $list    = $self->list;
    my $project = $list->project;

    # articles
    my %articles = map { $_->{id} => $_ } $list->articles->hri->all;

    # units: need to select all of project's units because of convertibility
    my %units = map { $_->{id} => $_ } $project->units->hri->all;

    # items
    my %items = map { $_->{id} => $_ } $list->items->hri->all;
    my %items_per_section;

    for my $item ( values %items ) {
        $item->{article}     = $articles{ $item->{article} };
        $item->{unit}        = $units{ $item->{unit} };
        $item->{ingredients} = [];

        push @{ $items_per_section{ $item->{article}{shop_section} } }, $item;
    }

    {    # add ingredients to each item
        my %ingredients_by_dish;

        my $ingredients = $list->items->search_related('ingredients')->hri;

        while ( my $ingredient = $ingredients->next ) {
            $ingredient->{article} = $articles{ $ingredient->{article} };
            $ingredient->{unit}    = $units{ $ingredient->{unit} };

            push @$_, $ingredient
              for (
                $items{ $ingredient->{item} }{ingredients},     # add $ingredient{} to %items
                $ingredients_by_dish{ $ingredient->{dish} },    # collect $ingredient{} for dish
              );
        }

        my $dishes =
          $list->items->search_related('ingredients')->search_related( 'dish', undef, { distinct => 1 } )
          ->hri;

        while ( my $dish = $dishes->next ) {
            for my $ingredient ( @{ $ingredients_by_dish{ $dish->{id} } } ) {
                $ingredient->{dish} = $dish;
            }
        }
    }

    {    # add convertible_into units to each item
        my $articles_units = $list->articles->search_related(
            'articles_units',
            {
                'unit.to_quantity_default' => { '!=' => undef },    # w/o conversion factor no conversion possible
            },
            {
                distinct => 1,        # otherwise sometimes returns (article_id, unit_id) twice
                join     => 'unit',
            }
        )->hri;

        my %convertible_units;        # units by article, quantity

        while ( my $article_unit = $articles_units->next ) {
            my $article = $articles{ $article_unit->{article} } || die $article_unit->{article};
            my $unit    = $units{ $article_unit->{unit} }       || die $article_unit->{unit};

            push @{ $convertible_units{ $article->{id} }{ $unit->{quantity} } }, $unit;
        }

        for my $item ( values %items ) {
            my $units = $convertible_units{ $item->{article}{id} }{ $item->{unit}{quantity} };

            if ( $units and @$units > 1 ) {
                $item->{convertible_into} = [ grep { $_->{id} != $item->{unit}{id} } @$units ];
            }
            else {
                $item->{convertible_into} = [];
            }
        }
    }

    # shop sections
    my @sections = $list->articles->search_related('shop_section')->hri->all;

    for my $section (@sections) {
        $section->{items} = $items_per_section{ $section->{id} };
    }

    # sort products alphabetically
    for my $section (@sections) {
        my $items = $section->{items};
        @$items = sort { $a->{article}{name} cmp $b->{article}{name} } @$items;
    }

    # sort sections
    @sections = sort { $a->{name} cmp $b->{name} } @sections;

    # items with no shop section
    if ( my $items = $items_per_section{''} ) {
        push @sections, { items => $items };
    }

    $self->units( [ values %units ] );
    $self->shop_sections( \@sections );
}

__PACKAGE__->meta->make_immutable;

1;
