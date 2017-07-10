package Coocook::Controller::Print;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use utf8;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Print - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub auto : Private {
    my ( $self, $c ) = @_;

    push @{ $c->stash->{css} }, 'print.css';
}

sub index : Path Args(0) {
    my ( $self, $c ) = @_;

    # TODO find a way to exclude this method when adding 'print.css' (5 lines above)
    my $css = $c->stash->{css};
    @$css = grep { $_ ne 'print.css' } @$css;    # remove 'print.css' again :-/

    my $project = $c->stash->{my_project};

    # can't use get_column(date) here because $meal->date() inflates DateTime object
    my @days =
      map { $_->date } $project->meals->search( undef, { columns => 'date', distinct => 1 } )->all;

    my $lists = $project->purchase_lists->search( undef, { order_by => 'date' } );

    my @projects = $c->model('Schema::Project')->all;

    $c->stash(
        days     => \@days,
        lists    => $lists,
        projects => \@projects,
    );
}

sub day : Local Args(3) {
    my ( $self, $c, $year, $month, $day ) = @_;

    my $dt = DateTime->new(
        year  => $year,
        month => $month,
        day   => $day,
    );

    my %meals;
    my @meals;

    {
        my $meals = $c->model('Schema::Meal')->search(
            {
                date => $dt->ymd,
            },
            {
                columns  => [ 'id', 'name' ],
                order_by => 'id',
            }
        );

        while ( my $meal = $meals->next ) {
            push @meals,
              $meals{ $meal->id } = {
                name            => $meal->name,
                dishes          => [],
                prepared_dishes => [],
              };
        }
    }

    my %dishes;

    {
        my $dishes = $c->model('Schema::Dish')->search(
            [
                meal            => { -in => [ keys %meals ] },
                prepare_at_meal => { -in => [ keys %meals ] },
            ],
            {
                prefetch => 'prepare_at_meal',
            }
        );

        while ( my $dish = $dishes->next ) {
            my %dish = (
                id          => $dish->id,
                name        => $dish->name,
                servings    => $dish->servings,
                preparation => $dish->preparation,
                description => $dish->description,
                ingredients => [],
            );

            $dishes{ $dish->id } = \%dish;

            if ( exists $meals{ $dish->get_column('meal') } ) {    # is a dish on this day
                if ( my $meal = $dish->prepare_at_meal ) {
                    $dish{prepare_at_meal} = {
                        date => $dish->prepare_at_meal->date,
                        name => $dish->prepare_at_meal->name,
                    };
                }

                push @{ $meals{ $dish->get_column('meal') }{dishes} }, \%dish;
            }

            if ( my $prepare_at_meal = $dish->get_column('prepare_at_meal') ) {
                if ( exists $meals{$prepare_at_meal} ) {           # dish is prepared on this day
                    $dish{meal} = {
                        name => $dish->meal->name,
                        date => $dish->meal->date,
                    };

                    push @{ $meals{ $dish->prepare_at_meal->id }{prepared_dishes} }, \%dish;
                }
            }
        }
    }

    {
        my $ingredients = $c->model('Schema::DishIngredient')->search(
            {
                dish => { -in => [ keys %dishes ] },
            },
            {
                order_by => 'position',
                prefetch => [ 'article', 'unit' ],
            }
        );

        while ( my $ingredient = $ingredients->next ) {
            push @{ $dishes{ $ingredient->get_column('dish') }{ingredients} },
              {
                prepare => $ingredient->prepare,
                value   => $ingredient->value,
                unit    => {
                    short_name => $ingredient->unit->short_name,
                    long_name  => $ingredient->unit->long_name,
                },
                article => {
                    name    => $ingredient->article->name,
                    comment => $ingredient->article->comment,
                },
                comment => $ingredient->comment,
              };
        }
    }

    $c->stash(
        day   => $dt,
        meals => \@meals,
    );
}

sub project : Local Args(1) {
    my ( $self, $c, $id ) = @_;

    my $project = $c->model('Schema::Project')->find($id);

    my %days;

    my $meals = $project->meals->search(
        undef,
        {
            prefetch => 'dishes',
        }
    );

    while ( my $meal = $meals->next ) {
        my @dishes = map { $_->name } $meal->dishes->all;

        my $day = $days{ $meal->date } ||= {
            date  => $meal->date,
            meals => [],
        };

        push @{ $day->{meals} },
          {
            name   => $meal->name,
            dishes => \@dishes,
          };

    }

    my @days = @days{ sort keys %days };

    $c->stash(
        project => $project,
        days    => \@days,
    );
}

sub purchase_list : Local Args(1) {
    my ( $self, $c, $id ) = @_;

    # get data from purchase list editor
    $c->forward( '/purchase_list/edit', [$id] );
}

=encoding utf8

=head1 AUTHOR

Daniel Böhmer,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
