package Coocook::Controller::Meal;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Meal - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub delete : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;

    my $meal = $c->model('Schema::Meal')->find($id);
    $meal->delete;
    $c->detach( redirect => [$meal] );
}

sub create : Local Args(0) POST {
    my ( $self, $c ) = @_;
    my $meal = $c->model('Schema::Meal')->create(
        {
            project => scalar $c->req->param('project'),
            date    => scalar $c->req->param('date'),
            name    => scalar $c->req->param('name'),
            comment => scalar $c->req->param('comment'),
        }
    );
    $c->detach( redirect => [$meal] );
}

sub update : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;
    my $meal = $c->model('Schema::Meal')->find($id);

    $meal->update(
        {
            name    => scalar $c->req->param('name'),
            comment => scalar $c->req->param('comment'),
        }
    );
    $c->detach( redirect => [$meal] );
}

sub redirect : Private {
    my ( $self, $c, $meal ) = @_;
    $c->response->redirect( $c->uri_for_action( '/project/edit', $meal->get_column('project') ) );
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
