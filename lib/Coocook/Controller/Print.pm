package Coocook::Controller::Print;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use utf8;

BEGIN { extends 'Catalyst::Controller' }

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

sub index : GET Chained('/project/base') PathPart('print') Args(0) {
    my ( $self, $c ) = @_;

    # TODO find a way to exclude this method when adding 'print.css' (5 lines above)
    my $css = $c->stash->{css};
    @$css = grep { $_ ne 'print.css' } @$css;    # remove 'print.css' again :-/

    my $project = $c->stash->{project} || die;

    # can't use get_column(date) here because $meal->date() inflates DateTime object
    my @days =
      map { $_->date } $project->meals->search( undef, { columns => 'date', distinct => 1 } )->all;

    my $lists = $project->purchase_lists->search( undef, { order_by => 'date' } );

    my @projects = $c->model('DB::Project')->all;

    $c->stash(
        days     => \@days,
        lists    => $lists,
        projects => \@projects,
    );
}

sub day : GET Chained('/project/base') PathPart('print/day') Args(3) {
    my ( $self, $c, $year, $month, $day ) = @_;

    my $dt = DateTime->new(
        year  => $year,
        month => $month,
        day   => $day,
    );

    $c->stash(
        day => $dt,
        meals => $c->model('Plan')->day( $c->project, $dt ),
    );
}

sub project : GET Chained('/project/base') PathPart('print/project') Args(0) {
    my ( $self, $c, $id ) = @_;

    $c->stash( days => $c->model('Plan')->project( $c->project ) );
}

sub purchase_list : GET Chained('/project/base') PathPart('print/purchase_list') Args(1) {
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
