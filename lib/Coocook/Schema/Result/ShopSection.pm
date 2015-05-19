package Coocook::Schema::Result::ShopSection;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("shop_sections");

__PACKAGE__->add_columns(
    id   => { data_type => "int", is_auto_increment => 1 },
    name => { data_type => "text" },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( ['name'] );

__PACKAGE__->has_many(
    articles => 'Coocook::Schema::Result::Article',
    'shop_section'
);

__PACKAGE__->meta->make_immutable;

1;
