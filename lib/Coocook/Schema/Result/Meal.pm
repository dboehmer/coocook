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

__PACKAGE__->has_many( dishes => 'Coocook::Schema::Result::Dish' );

__PACKAGE__->has_many(
    prepared_dishes => 'Coocook::Schema::Result::Dish',
    'prepare_at_meal'
);

__PACKAGE__->meta->make_immutable;

sub deletable {
    my $self = shift;

    return $self->dishes->count == 0;
}

1;
