package Coocook::Model::Ingredients;

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

sub build_project { shift->ingredients->first->project }

has reposition_url_factory => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

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
                id             => $ingredient->id,
                prepare        => $ingredient->prepare,
                value          => $ingredient->value,
                comment        => $ingredient->comment,
                unit           => $units{ $ingredient->get_column('unit') },
                article        => $articles{ $ingredient->get_column('article') },
                reposition_url => $self->reposition_url_factory->( $ingredient->id ),
              };
        }
    }

    $self->all_articles($articles);
    $self->all_units($units);

    return \@ingredients;
}

1;