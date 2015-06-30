package Coocook::Schema::Result::Article;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("articles");

__PACKAGE__->add_columns(
    id                => { data_type => "int", is_auto_increment => 1 },
    shop_section      => { data_type => "int", is_nullable       => 1 },
    shelf_life_days   => { data_type => "int", is_nullable       => 1 },
    preorder_servings => { data_type => "int", is_nullable       => 1 },
    preorder_workdays => { data_type => "int", is_nullable       => 1 },
    name              => { data_type => "text" },
    comment           => { data_type => "text" },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( ['name'] );

__PACKAGE__->belongs_to(
    shop_section => 'Coocook::Schema::Result::ShopSection' );

__PACKAGE__->has_many( articles_tags => 'Coocook::Schema::Result::ArticleTag' );
__PACKAGE__->many_to_many( tags => articles_tags => 'tag' );

__PACKAGE__->has_many(
    articles_units => 'Coocook::Schema::Result::ArticleUnit' );
__PACKAGE__->many_to_many( units => articles_units => 'unit' );

__PACKAGE__->meta->make_immutable;

sub unit_ids {
    my $self = shift;

    return { map { $_ => 1 } $self->units->get_column('id')->all };
}

1;
