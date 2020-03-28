package Coocook::Schema::Result::RecipeOfTheDay;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('recipes_of_the_day');

__PACKAGE__->add_columns(
    id            => { data_type => 'integer', is_auto_increment => 1 },
    recipe_id     => { data_type => 'integer' },
    day           => { data_type => 'date' },
    admin_comment => { data_type => 'text', default_value => '' },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( [ 'recipe_id', 'day' ] );

__PACKAGE__->belongs_to( recipe => 'Coocook::Schema::Result::Recipe', 'recipe_id' );

__PACKAGE__->meta->make_immutable;

1;
