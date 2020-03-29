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
        $item->{article}     = $articles{ $item->{article_id} };
        $item->{unit}        = $units{ $item->{unit_id} };
        $item->{ingredients} = [];

        push @{ $items_per_section{ $item->{article}{shop_section_id} } }, $item;
    }

    {    # add ingredients to each item
        my %ingredients_by_dish;

        my $ingredients = $list->items->search_related('ingredients')->hri;

        while ( my $ingredient = $ingredients->next ) {
            $ingredient->{article} = $articles{ $ingredient->{article_id} };
            $ingredient->{unit}    = $units{ $ingredient->{unit_id} };

            push @$_, $ingredient
              for (
                $items{ $ingredient->{item_id} }{ingredients},     # add $ingredient{} to %items
                $ingredients_by_dish{ $ingredient->{dish_id} },    # collect $ingredient{} for dish
              );
        }

        my $dishes =
          $list->items->search_related('ingredients')->search_related( 'dish', undef, { distinct => 1 } )
          ->hri;

        my %meals = map { $_->{id} => $_ }
          $project->meals->hri->all;    # fetch all meals is probably more efficient than complex query

        for my $meal ( values %meals ) {
            $meal->{date} = $project->parse_date( $meal->{date} );
        }

        while ( my $dish = $dishes->next ) {
            $dish->{meal} = $meals{ $dish->{meal_id} } || die;

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
            my $article = $articles{ $article_unit->{article_id} } || die $article_unit->{article_id};
            my $unit    = $units{ $article_unit->{unit_id} }       || die $article_unit->{unit_id};

            push @{ $convertible_units{ $article->{id} }{ $unit->{quantity_id} } }, $unit;
        }

        for my $item ( values %items ) {
            my $units = $convertible_units{ $item->{article}{id} }{ $item->{unit}{quantity_id} };

            if ( $units and @$units > 1 ) {
                $item->{convertible_into} = [ grep { $_->{id} != $item->{unit}{id} } @$units ];
            }
            else {
                $item->{convertible_into} = [];
            }
        }
    }

    # shop sections
    my @sections =
      $list->articles->search_related( shop_section => undef, { distinct => 1 } )->hri->all;

    for my $section (@sections) {
        $section->{items} = $items_per_section{ $section->{id} };
    }

    # sort sections
    @sections = sort { $a->{name} cmp $b->{name} } @sections;

    # items with no shop section
    if ( my $items = $items_per_section{''} ) {
        push @sections, { items => $items };
    }

    # sort products alphabetically
    for my $section (@sections) {
        my $items = $section->{items};

        # https://en.wikipedia.org/wiki/Schwartzian_transform
        @$items = sort {    # sort by
            $a->{article}{name} cmp $b->{article}{name}                                 # 1. article name
              or $a->{unit}{to_quantity_default} <=> $b->{unit}{to_quantity_default}    # 2. conversion factor
              or $a->{unit}{id} <=> $b->{unit}{id}                                      # 3. unit ID
        } @$items;
    }

    $self->units( [ values %units ] );
    $self->shop_sections( \@sections );
}

__PACKAGE__->meta->make_immutable;

1;
