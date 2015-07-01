package Coocook::Controller::Print;

use DateTime;
use Moose;
use namespace::autoclean;
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

    my @projects = $c->model('Schema::Project')->all;
    my @days =
      map { $_->date }
      $c->model('Schema::Meal')
      ->search( undef, { columns => 'date', distinct => 1 } )->all;

    $c->stash(
        days     => \@days,
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

    my $meals = $c->model('Schema::Meal')->search(
        {
            date => $dt->ymd,
        }
    );

    $c->stash(
        day   => $dt,
        meals => $meals,
    );
}

sub project : Local Args(1) {
    my ( $self, $c, $id ) = @_;

    my $project = $c->model('Schema::Project')->find($id);

    my @days = (
        {
            date  => DateTime->today,
            meals => [
                {
                    name   => "Frühstück",
                    dishes => [qw<Eier Brötchen>],
                },
                {
                    name   => "Mittagessen",
                    dishes => [qw<Käsespätzle Pudding>],
                },
            ],
        },
        {
            date  => DateTime->today->add( days => 1 ),
            meals => [
                {
                    name   => "Abschluss-Brunch",
                    dishes => ["Reste"],
                }
            ],
        },
    );

    $c->stash(
        project => $project,
        days    => \@days,
    );
}

sub shopping_list : Local Args(1) {
    my ( $self, $c, $id ) = @_;

    my $sections = [
        {
            name  => "Backwaren",
            items => [
                {
                    value       => 23,
                    unit        => { short_name => "Kg" },
                    offset      => -5,
                    comment     => "Noch 5kg im Vorrat",
                    article     => { name => "Haferflocken" },
                    ingredients => [
                        {
                            date    => "2014-08-01",
                            value   => 20,
                            unit    => "Kg",
                            dish    => "SOLA-Pampe",
                            comment => "Hochwertige kaufen!"
                        },
                        {
                            date  => "2014-08-02",
                            value => 3,
                            unit  => "Kg",
                            dish  => "Eklige Suppe"
                        },
                    ],
                },
                {
                    value       => 100,
                    unit        => { short_name => "Stk" },
                    offset      => undef,
                    comment     => undef,
                    article     => { name => "Äpfel" },
                    ingredients => [
                        {
                            date  => "2014-08-02",
                            value => 100,
                            unit  => "Stk",
                            dish  => "Dessert"
                        },
                    ],
                },
            ],
        },
        {
            name  => "Obst & Gemüse",
            items => [],
        },
    ];

    # sort products alphabetically
    for my $section (@$sections) {
        $section->{items} =
          [ sort { $a->{article}{name} cmp $b->{article}{name} }
              @{ $section->{items} } ];
    }

    # sort sections
    $sections = [ sort { $a->{name} cmp $b->{name} } @$sections ];

    $c->stash( sections => $sections );
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
