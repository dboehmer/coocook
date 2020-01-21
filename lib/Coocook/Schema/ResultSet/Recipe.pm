package Coocook::Schema::ResultSet::Recipe;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::SortByName');

__PACKAGE__->meta->make_immutable;

sub public {
    my $self = shift;

    return $self->search(
        {
            -bool => 'project.is_public',
        },
        {
            join => 'project',
        }
    );
}

1;
