package Coocook::Schema::Result::DishIngredient;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->load_components(qw< +Coocook::Schema::Component::Result::Convertible Ordered >);

__PACKAGE__->table('dish_ingredients');

__PACKAGE__->add_columns(
    id         => { data_type => 'int', is_auto_increment => 1 },
    position   => { data_type => 'int', default_value     => 1 },
    dish_id    => { data_type => 'int' },
    prepare    => { data_type => 'bool' },
    article_id => { data_type => 'int' },
    unit_id    => { data_type => 'int' },
    value      => { data_type => 'real' },
    comment    => { data_type => 'text' },
    item_id    => { data_type => 'int', is_nullable => 1 },    # from purchase list
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->position_column('position');

__PACKAGE__->grouping_column('dish_id');

__PACKAGE__->belongs_to( article => 'Coocook::Schema::Result::Article', 'article_id' );
__PACKAGE__->belongs_to( dish    => 'Coocook::Schema::Result::Dish',    'dish_id' );
__PACKAGE__->belongs_to( unit    => 'Coocook::Schema::Result::Unit',    'unit_id' );

__PACKAGE__->belongs_to(
    article_unit => 'Coocook::Schema::Result::ArticleUnit',
    {
        'foreign.article_id' => 'self.article_id',
        'foreign.unit_id'    => 'self.unit_id',
    }
);

__PACKAGE__->belongs_to(
    item => 'Coocook::Schema::Result::Item',
    'item_id', { on_delete => 'SET NULL' }
);

__PACKAGE__->meta->make_immutable;

sub assign_to_purchase_list {
    my ( $self, $list ) = @_;

    my $item;

    $self->txn_do(
        sub {
            $item = $self->result_source->schema->resultset('Item')->add_or_create(
                {
                    purchase_list_id => ref $list ? $list->id : $list,    # TODO stricter interface?
                    article_id       => $self->article_id,
                    unit_id          => $self->unit_id,
                    value            => $self->value,
                }
            );

            $self->update( { item_id => $item->id } );
        }
    );

    return $item;
}

=head2 update_on_purchase_list()

Returns boolish value indicating if there's an item that was updated

=cut

sub update_on_purchase_list {
    my $self = shift;

    $self->txn_do(
        sub {
            my $item = $self->item or return;

            $item->update_from_ingredients;
        }
    ) or return;

    return 1;
}

=head2 remove_from_purchase_list()

Returns boolish value indicating if there's an item that was updated

=cut

sub remove_from_purchase_list {
    my $self = shift;

    $self->txn_do(
        sub {
            my $item = $self->item or return;

            $self->update( { item_id => undef } );

            if ( $item->ingredients->results_exist ) {
                $item->update_from_ingredients;
            }

            else {    # item belongs to no other ingredients
                $item->delete;
            }
        }
    ) or return;

    return 1;
}

1;
