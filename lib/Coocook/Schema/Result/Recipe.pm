package Coocook::Schema::Result::Recipe;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use Coocook::Util;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('recipes');

__PACKAGE__->add_columns(
    id          => { data_type => 'integer', is_auto_increment => 1 },
    project_id  => { data_type => 'integer' },
    name        => { data_type => 'text' },
    preparation => { data_type => 'text' },
    description => { data_type => 'text' },
    servings    => { data_type => 'integer' },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( [ 'project_id', 'name' ] );

__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project', 'project_id' );

__PACKAGE__->has_many(
    dishes => 'Coocook::Schema::Result::Dish',
    'from_recipe_id',
    {
        cascade_delete => 0,    # recipes with dishes may not be deleted
                                # TODO maybe ON DELETE SET NULL?
    }
);

__PACKAGE__->has_many(
    ingredients => 'Coocook::Schema::Result::RecipeIngredient',
    'recipe_id',
    {
        cascade_copy => 1,
    }
);

__PACKAGE__->has_many(
    ingredients_sorted => 'Coocook::Schema::Result::RecipeIngredient',
    'recipe_id',
    {
        cascade_copy => 1,            # see above
        order_by     => 'position',
    }
);

__PACKAGE__->has_many( recipes_tags => 'Coocook::Schema::Result::RecipeTag', 'recipe_id' );
__PACKAGE__->many_to_many( tags => recipes_tags => 'tag' );

__PACKAGE__->meta->make_immutable;

sub duplicate {
    my ( $self, $args ) = @_;

    $args->{name} // die "no name defined in \$args";

    return $self->copy($args);
}

sub url_name { Coocook::Util::url_name( shift->name ) }

1;
