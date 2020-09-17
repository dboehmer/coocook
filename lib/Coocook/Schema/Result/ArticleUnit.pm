package Coocook::Schema::Result::ArticleUnit;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('articles_units');

__PACKAGE__->add_columns(
    article_id => { data_type => 'integer' },
    unit_id    => { data_type => 'integer' },
);

__PACKAGE__->set_primary_key(qw<article_id unit_id>);

__PACKAGE__->belongs_to( article => 'Coocook::Schema::Result::Article', 'article_id' );
__PACKAGE__->belongs_to( unit    => 'Coocook::Schema::Result::Unit',    'unit_id' );

__PACKAGE__->has_many(
    dish_ingredients => 'Coocook::Schema::Result::DishIngredient',
    {
        'foreign.article_id' => 'self.article_id',
        'foreign.unit_id'    => 'self.unit_id',
    },
    {
        cascade_delete => 0,    # articles_units with dish_ingredients may not be deleted
    }
);

__PACKAGE__->has_many(
    items => 'Coocook::Schema::Result::Item',
    {
        'foreign.article_id' => 'self.article_id',
        'foreign.unit_id'    => 'self.unit_id',
    },
    {
        cascade_delete => 0,    # articles_units with items may not be deleted
    }
);

__PACKAGE__->has_many(
    recipe_ingredients => 'Coocook::Schema::Result::RecipeIngredient',
    {
        'foreign.article_id' => 'self.article_id',
        'foreign.unit_id'    => 'self.unit_id',
    },
    {
        cascade_delete => 0,    # articles_units with recipe_ingredients may not be deleted
    }
);

__PACKAGE__->meta->make_immutable;

1;
