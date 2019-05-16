package Coocook::Schema::Result::Item;

# ABSTRACT: each database row is 1 item of a purchase list and subsumes 1 or more dish ingredients

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->load_components('+Coocook::Schema::Component::Result::Convertible');

__PACKAGE__->table("items");

__PACKAGE__->add_columns(
    id            => { data_type => 'int', is_auto_increment => 1 },
    purchase_list => { data_type => 'int' },
    value         => { data_type => 'real' },
    offset        => { data_type => 'real', default_value => 0 },
    unit          => { data_type => 'int' },
    article       => { data_type => 'int' },
    purchased     => { data_type => 'bool', default_value => 0 },
    comment       => { data_type => 'text' },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( [qw<purchase_list article unit>] );

__PACKAGE__->belongs_to( article       => 'Coocook::Schema::Result::Article' );
__PACKAGE__->belongs_to( purchase_list => 'Coocook::Schema::Result::PurchaseList' );
__PACKAGE__->belongs_to( unit          => 'Coocook::Schema::Result::Unit' );
__PACKAGE__->belongs_to(
    article_unit => 'Coocook::Schema::Result::ArticleUnit',
    {
        'foreign.article' => 'self.article',
        'foreign.unit'    => 'self.unit',
    }
);

__PACKAGE__->has_many( ingredients => 'Coocook::Schema::Result::DishIngredient', 'item' );

__PACKAGE__->meta->make_immutable;

sub convert {
    my ( $self => $unit2 ) = @_;

    $self->txn_do(
        sub {
            my $unit1 = $self->unit;

            $unit1->get_column('quantity') == $unit2->get_column('quantity')
              or die "Units not of same quantity";

            my $factor = $unit1->to_quantity_default / $unit2->to_quantity_default;

            my $unit2_item = $self->result_source->resultset->find(
                {
                    purchase_list => $self->get_column('purchase_list'),
                    article       => $self->get_column('article'),
                    unit          => $unit2->id,
                }
            );

            if ($unit2_item) {
                $unit2_item->update(
                    {
                        value  => $unit2_item->value + $self->value * $factor,
                        offset => $unit2_item->offset + $self->offset * $factor,
                    }
                );

                $self->ingredients->update( { item => $unit2_item->id } );

                $self->delete;

                return $unit2_item;
            }
            else {
                $self->update(
                    {
                        unit   => $unit2->id,
                        value  => $self->value * $factor,
                        offset => $self->offset * $factor,
                    }
                );

                return $self;
            }
        }
    );
}

1;
