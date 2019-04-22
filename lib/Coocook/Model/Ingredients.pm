package Coocook::Model::Ingredients;

# ABSTRACT: business logic for plain data structures from Dish- or RecipeIngredients

use Moose;
use Moose::Util::TypeConstraints;

class_type 'Coocook::Schema::ResultSet::DishIngredient';
class_type 'Coocook::Schema::ResultSet::RecipeIngredient';

has all_articles => (
    is  => 'rw',
    isa => 'ArrayRef[Coocook::Schema::Result::Article]',
);

has all_units => (
    is  => 'rw',
    isa => 'ArrayRef[Coocook::Schema::Result::Unit]',
);

has ingredients => (
    is  => 'ro',
    isa => 'Coocook::Schema::ResultSet::DishIngredient | Coocook::Schema::ResultSet::RecipeIngredient',
    required => 1,
);

has project => (
    is      => 'ro',
    isa     => 'Coocook::Schema::Result::Project',
    lazy    => 1,
    builder => 'build_project',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my %args = @_;

    if ( my $dish = delete $args{dish} ) {
        $args{project}     = $dish->project;
        $args{ingredients} = $dish->ingredients;
    }
    elsif ( my $recipe = delete $args{recipe} ) {
        $args{project}     = $recipe->project;
        $args{ingredients} = $recipe->ingredients;
    }

    return $class->$orig(%args);
};

sub build_project { shift->ingredients->one_row->project }

sub as_arrayref {
    my $self = shift;

    my ( $articles => $units ) = $self->project->articles_cached_units;

    my %articles = map { $_->id => $_ } @$articles;
    my %units    = map { $_->id => $_ } @$units;

    my @ingredients;
    {
        my $ingredients = $self->ingredients->sorted;

        while ( my $ingredient = $ingredients->next ) {
            push @ingredients,
              {
                id      => $ingredient->id,
                prepare => $ingredient->prepare,
                value   => $ingredient->value,
                comment => $ingredient->comment,
                unit    => $units{ $ingredient->get_column('unit') },
                article => $articles{ $ingredient->get_column('article') },
              };
        }
    }

    $self->all_articles($articles);
    $self->all_units($units);

    return \@ingredients;
}

1;
