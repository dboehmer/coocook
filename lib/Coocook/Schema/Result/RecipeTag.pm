package Coocook::Schema::Result::RecipeTag;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('recipes_tags');

__PACKAGE__->add_columns(
    recipe_id => { data_type => 'integer' },
    tag_id    => { data_type => 'integer' },
);

__PACKAGE__->set_primary_key(qw<recipe_id tag_id>);

__PACKAGE__->belongs_to( recipe => 'Coocook::Schema::Result::Recipe', 'recipe_id' );
__PACKAGE__->belongs_to( tag    => 'Coocook::Schema::Result::Tag',    'tag_id' );

__PACKAGE__->meta->make_immutable;

1;
