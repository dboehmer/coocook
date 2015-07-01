package Coocook::Schema::Result::ArticleUnit;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("articles_units");

__PACKAGE__->add_columns(
    article => { data_type => "int" },
    unit    => { data_type => "int" },
);

__PACKAGE__->set_primary_key(qw<article unit>);

__PACKAGE__->belongs_to( article => 'Coocook::Schema::Result::Article' );
__PACKAGE__->belongs_to( unit    => 'Coocook::Schema::Result::Unit' );

__PACKAGE__->has_many(
    dish_ingredients => 'Coocook::Schema::Result::DishIngredient',
    {
        'foreign.article' => 'self.article',
        'foreign.unit'    => 'self.unit',
    }
);

__PACKAGE__->has_many(
    items => 'Coocook::Schema::Result::Item',
    {
        'foreign.article' => 'self.article',
        'foreign.unit'    => 'self.unit',
    }
);

__PACKAGE__->has_many(
    recipe_ingredients => 'Coocook::Schema::Result::RecipeIngredient',
    {
        'foreign.article' => 'self.article',
        'foreign.unit'    => 'self.unit',
    }
);

__PACKAGE__->meta->make_immutable;

1;
