package Coocook::Controller::Meal;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Meal - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub edit : Path : Args(1) {
    my ( $self, $c, $id ) = @_;
    my $meal = $c->model('Schema::Meal')->find($id);
    $c->stash(
        project => $meal->project,
        meal    => $meal,
    );
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
