package Coocook::Schema::Result::Meal;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("meals");

__PACKAGE__->add_columns(
    id      => { data_type => 'int', is_auto_increment => 1 },
    project => { data_type => 'int' },
    date    => { data_type => 'date' },
    name    => { data_type => 'text' },
    comment => { data_type => 'text' },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( [qw<project date name>] );

__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project' );

__PACKAGE__->has_many(
    dishes => 'Coocook::Schema::Result::Dish',
    'meal',
    {
        cascade_delete => 1,    # TODO meals with dishes should not be deleted in the user interface
                                # but dishes have no FK on project, so CASCADE is necessary
    }
);

__PACKAGE__->has_many(
    prepared_dishes => 'Coocook::Schema::Result::Dish',
    'prepare_at_meal',
    {
        cascade_delete => 0,    # meals with prepared dishes may not be deleted
    }
);

__PACKAGE__->meta->make_immutable;

sub deletable {
    my $self = shift;

    return !$self->dishes->exists;
}

1;
