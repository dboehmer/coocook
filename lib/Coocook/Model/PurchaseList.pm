package Coocook::Model::PurchaseList;

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

    # units: can't narrow down because needs convertible units
    my %units = map { $_->{id} => $_ } $project->units->hri->all;

    {
        my %default_unit;    # holds true value for all IDs of default units
        my %convertible;     # holds arrayrefs for convertible units per quantity

        my $quantities = $project->quantities->hri;

        while ( my $quantity = $quantities->next ) {
            if ( my $unit = $quantity->{default_unit} ) {
                $default_unit{$unit} = 1;
            }

            $convertible{ $quantity->{id} } = [];
        }

        for my $unit ( values %units ) {
            if ( $default_unit{ $unit->{id} } ) {
                $unit->{is_default_quantity} = 1;
            }
            elsif ( $unit->{to_quantity_default} ) {
                $unit->{can_be_quantity_default} = 1;
            }
            else {
                next;
            }

            # unit is either quantity default or can be converted to
            push @{ $convertible{ $unit->{quantity} } }, $unit;
        }

        # clone list of convertibles and exclude unit itself
        for my $units ( values %convertible ) {
            for my $unit (@$units) {
                my @convertible = grep { $_->{id} != $unit->{id} } @$units;

                # avoid circular references
                weaken $_ for @convertible;

                $unit->{convertible_into} = \@convertible;
            }
        }
    }

    # items
    my %items = map { $_->{id} => $_ } $list->items->hri->all;
    my %items_per_section;

    for my $item ( values %items ) {
        $item->{article}     = $articles{ $item->{article} };
        $item->{unit}        = $units{ $item->{unit} };
        $item->{ingredients} = [];

        push @{ $items_per_section{ $item->{article}{shop_section} } }, $item;
    }

    # ingredients
    {
        my %ingredients_by_dish;

        my $ingredients = $list->items->ingredients->hri;

        while ( my $ingredient = $ingredients->next ) {
            $ingredient->{article} = $articles{ $ingredient->{article} };
            $ingredient->{unit}    = $units{ $ingredient->{unit} };

            push @$_, $ingredient
              for (
                $items{ $ingredient->{item} }{ingredients},     # add $ingredient{} to %items
                $ingredients_by_dish{ $ingredient->{dish} },    # collect $ingredient{} for dish
              );
        }

        my $dishes = $project->dishes;
        $dishes = $dishes->search( { $dishes->me('id') => { -in => [ keys %ingredients_by_dish ] } } )->hri;

        while ( my $dish = $dishes->next ) {
            for my $ingredient ( @{ $ingredients_by_dish{ $dish->{id} } } ) {
                $ingredient->{dish} = $dish;
            }
        }
    }

    # shop sections
    my @sections = $project->shop_sections->search(
        { id => { -in => [ grep { length } keys %items_per_section ] } } )->hri->all;

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
