package Coocook::Schema::Result::Project;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("projects");

__PACKAGE__->add_columns(
    id          => { data_type => 'int', is_auto_increment => 1 },
    name        => { data_type => 'text' },
    url_name    => { data_type => 'text' },
    url_name_fc => { data_type => 'text' }, # fold cased
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( ['name'], ['url_name'], ['url_name_fc'] );

__PACKAGE__->has_many( articles       => 'Coocook::Schema::Result::Article' );
__PACKAGE__->has_many( meals          => 'Coocook::Schema::Result::Meal' );
__PACKAGE__->has_many( purchase_lists => 'Coocook::Schema::Result::PurchaseList' );
__PACKAGE__->has_many( quantities     => 'Coocook::Schema::Result::Quantity' );
__PACKAGE__->has_many( recipes        => 'Coocook::Schema::Result::Recipe' );
__PACKAGE__->has_many( shop_sections  => 'Coocook::Schema::Result::ShopSection' );
__PACKAGE__->has_many( tags           => 'Coocook::Schema::Result::Tag' );
__PACKAGE__->has_many( tag_groups     => 'Coocook::Schema::Result::TagGroup' );
__PACKAGE__->has_many( units          => 'Coocook::Schema::Result::Unit' );

__PACKAGE__->meta->make_immutable;

# pseudo-relationship
sub dishes {
    my $self = shift;

    return $self->result_source->schema->resultset('Dish')->search(
        {
            'meal.project' => $self->id,
        },
        {
            join => 'meal',
        }
    );
}

1;
