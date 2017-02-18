package Coocook::Schema::Result::RecipeIngredient;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->load_components('Ordered');

__PACKAGE__->table("recipe_ingredients");

__PACKAGE__->add_columns(
    id       => { data_type => 'int', is_auto_increment => 1 },
    position => { data_type => 'int', default_value     => 1 },
    recipe   => { data_type => 'int' },
    prepare  => { data_type => 'bool' },
    article  => { data_type => 'int' },
    unit     => { data_type => 'int' },
    value    => { data_type => 'real' },
    comment  => { data_type => 'text' },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->position_column('position');

__PACKAGE__->grouping_column('recipe');

__PACKAGE__->belongs_to( article => 'Coocook::Schema::Result::Article' );
__PACKAGE__->belongs_to( recipe  => 'Coocook::Schema::Result::Recipe' );
__PACKAGE__->belongs_to( unit    => 'Coocook::Schema::Result::Unit' );
__PACKAGE__->belongs_to(
    article_unit => 'Coocook::Schema::Result::ArticleUnit',
    {
        'foreign.article' => 'self.article',
        'foreign.unit'    => 'self.unit',
    }
);

__PACKAGE__->meta->make_immutable;

1;
