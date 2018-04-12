package Coocook::Schema::Result::DishIngredient;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->load_components(qw< +Coocook::Schema::Component::Result::Convertible Ordered >);

__PACKAGE__->table("dish_ingredients");

__PACKAGE__->add_columns(
    id       => { data_type => 'int', is_auto_increment => 1 },
    position => { data_type => 'int', default_value     => 1 },
    dish     => { data_type => 'int' },
    prepare  => { data_type => 'bool' },
    article  => { data_type => 'int' },
    unit     => { data_type => 'int' },
    value    => { data_type => 'real' },
    comment  => { data_type => 'text' },
    item     => { data_type => 'int', is_nullable       => 1 },    # from purchase list
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->position_column('position');

__PACKAGE__->grouping_column('dish');

__PACKAGE__->belongs_to( article => 'Coocook::Schema::Result::Article' );
__PACKAGE__->belongs_to( dish    => 'Coocook::Schema::Result::Dish' );
__PACKAGE__->belongs_to( item    => 'Coocook::Schema::Result::Item' );
__PACKAGE__->belongs_to( unit    => 'Coocook::Schema::Result::Unit' );
__PACKAGE__->belongs_to(
    article_unit => 'Coocook::Schema::Result::ArticleUnit',
    {
        'foreign.article' => 'self.article',
        'foreign.unit'    => 'self.unit',
    }
);

__PACKAGE__->meta->make_immutable;

sub assign_to_purchase_list {
    my ( $self, $list ) = @_;

    my $item;

    $self->txn_do(
        sub {
            $item = $self->result_source->schema->resultset('Item')->add_or_create(
                {
                    purchase_list => $list,
                    article       => $self->get_column('article'),
                    unit          => $self->get_column('unit'),
                    value         => $self->value,
                }
            );

            $self->update( { item => $item->id } );
        }
    );

    return $item;
}

sub remove_from_purchase_list {
    my $self = shift;

    $self->txn_do(
        sub {
            my $item = $self->item
              or return
              warn "Trying to remove ingredient " . $self->id . " that's not assigned to any purchase list";

            $self->update( { item => undef } );

            if ( $item->ingredients->exists ) {
                my $value = $self->value;

                # if item got converted to other unit, convert $value, too
                if ( $self->get_column('unit') != $item->get_column('unit') ) {
                    my $unit1 = $self->unit;
                    my $unit2 = $item->unit;

                    $unit1->get_column('quantity') == $unit2->get_column('quantity')
                      or die "Units not of same quantity";

                    $value *= $unit1->to_quantity_default / $unit2->to_quantity_default;
                }

                $item->update( { value => $item->value - $value } );
            }
            else {    # item belongs to other ingredients
                $item->delete;
            }
        }
    );

    return 1;
}

1;
