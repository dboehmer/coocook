package Coocook::Model::PurchaseList;

use Moose;
use Scalar::Util 'weaken';

has list => (
    is       => 'ro',
    isa      => 'Coocook::Schema::Result::PurchaseList',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

sub by_section {
    my $self = shift;

    my $list    = $self->list;
    my $project = $list->project;

    # articles
    my %articles = map { $_->{id} => $_ } $list->articles->inflate_hashes->all;

    # units: can't narrow down because needs convertible units
    my %units = map { $_->{id} => $_ } $project->units->inflate_hashes->all;

    my %default_units = map { $_ => 1 } $project->quantities->get_column('default_unit')->all;

    for my $unit ( values %units ) {
        if ( $default_units{ $unit->{id} } ) {
            $unit->{is_default_quantity} = 1;
        }
        elsif ( $unit->{to_quantity_default} ) {
            $unit->{can_be_quantity_default} = 1;

            $unit->{convertible_into} = [
                grep {
                          $_->{id} != $unit->{id}
                      and $_->{quantity} == $unit->{quantity}
                      and defined $_->{to_quantity_default}
                } values %units
            ];

            weaken $_ for @{ $unit->{convertible_into} };
        }
    }

    # items
    my %items = map { $_->{id} => $_ } $list->items->inflate_hashes->all;
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

        my $ingredients = $list->items->ingredients->inflate_hashes;

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
        $dishes = $dishes->search( { $dishes->me('id') => { -in => [ keys %ingredients_by_dish ] } } )
          ->inflate_hashes;

        while ( my $dish = $dishes->next ) {
            for my $ingredient ( @{ $ingredients_by_dish{ $dish->{id} } } ) {
                $ingredient->{dish} = $dish;
            }
        }
    }

    # shop sections
    my @sections = $project->shop_sections->search(
        { id => { -in => [ grep { length } keys %items_per_section ] } } )->inflate_hashes->all;

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

    return \@sections;
}

1;
