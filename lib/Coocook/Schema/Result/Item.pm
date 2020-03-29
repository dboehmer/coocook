package Coocook::Schema::Result::Item;

# ABSTRACT: each database row is 1 item of a purchase list and subsumes 1 or more dish ingredients

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->load_components('+Coocook::Schema::Component::Result::Convertible');

__PACKAGE__->table('items');

__PACKAGE__->add_columns(
    id               => { data_type => 'int', is_auto_increment => 1 },
    purchase_list_id => { data_type => 'int' },
    value            => { data_type => 'real' },
    offset           => { data_type => 'real', default_value => 0 },
    unit_id          => { data_type => 'int' },
    article_id       => { data_type => 'int' },
    purchased        => { data_type => 'bool', default_value => 0 },
    comment          => { data_type => 'text' },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( [qw<purchase_list_id article_id unit_id>] );

__PACKAGE__->belongs_to(
    purchase_list => 'Coocook::Schema::Result::PurchaseList',
    'purchase_list_id'
);

__PACKAGE__->belongs_to( article => 'Coocook::Schema::Result::Article', 'article_id' );
__PACKAGE__->belongs_to( unit    => 'Coocook::Schema::Result::Unit',    'unit_id' );

__PACKAGE__->belongs_to(
    article_unit => 'Coocook::Schema::Result::ArticleUnit',
    {
        'foreign.article_id' => 'self.article_id',
        'foreign.unit_id'    => 'self.unit_id',
    }
);

__PACKAGE__->has_many( ingredients => 'Coocook::Schema::Result::DishIngredient', 'item_id' );

__PACKAGE__->meta->make_immutable;

sub convert {
    my ( $self => $unit2 ) = @_;

    $self->txn_do(
        sub {
            my $unit1 = $self->unit;

            $unit1->quantity_id == $unit2->quantity_id
              or die "Units not of same quantity";

            my $factor = $unit1->to_quantity_default / $unit2->to_quantity_default;

            my $unit2_item = $self->result_source->resultset->find(
                {
                    purchase_list_id => $self->purchase_list_id,
                    article_id       => $self->article_id,
                    unit_id          => $unit2->id,
                }
            );

            if ($unit2_item) {
                $unit2_item->update(
                    {
                        value  => $unit2_item->value + $self->value * $factor,
                        offset => $unit2_item->offset + $self->offset * $factor,
                    }
                );

                $self->ingredients->update( { item_id => $unit2_item->id } );

                $self->delete;

                return $unit2_item;
            }
            else {
                $self->update(
                    {
                        unit_id => $unit2->id,
                        value   => $self->value * $factor,
                        offset  => $self->offset * $factor,
                    }
                );

                return $self;
            }
        }
    );
}

sub update_from_ingredients {
    my $self = shift;

    my $item_value = 0;

    for my $ingredient ( $self->ingredients->all ) {

        my $ingredient_value = $ingredient->value;

        if ( $self->unit_id != $ingredient->unit_id ) {
            my $unit1 = $ingredient->unit;
            my $unit2 = $self->unit;

            $unit1->quantity_id == $unit2->quantity_id
              or die "Units not of same quantity";

            $ingredient_value *= $unit1->to_quantity_default / $unit2->to_quantity_default;
        }

        $item_value += $ingredient_value;
    }

    $self->update(
        {
            value  => $item_value,
            offset => 0
        }
    );
}

1;
