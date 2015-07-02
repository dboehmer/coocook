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

    my $project = $c->stash->{my_project};

    my @days =
      map { $_->date }
      $project->meals->search( undef, { columns => 'date', distinct => 1 } )
      ->all;

    my $lists =
      $project->purchase_lists->search( undef, { order_by => 'date' } );

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
