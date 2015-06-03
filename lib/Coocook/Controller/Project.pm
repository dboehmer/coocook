package Coocook::Controller::Project;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Project - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

# override begin() in Controller::Root
sub begin : Private { }

sub index : Path('/projects') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( projects => $c->model('Schema::Project'), );
}

sub edit : Path : Args(1) {
    my ( $self, $c, $id ) = @_;
    my $project = $c->model('Schema::Project')->find($id);

    my $days = do {
        my @meals = $project->meals->all;

        my %days;

        push @{ $days{ $_->date }{meals} }, $_ for @meals;

        $days{$_}{date} = $_ for keys %days;

        [ values %days ];
    };

    $c->stash(
        project => $project,
        days    => $days,
    );
}

sub create : Local : POST {
    my ( $self, $c, $id ) = @_;
    my $project = $c->model('Schema::Project')
      ->create( { name => $c->req->param('name') } );
    $c->detach( 'redirect', [ $project->id ] );
}

sub select : Local Args(1) {
    my ( $self, $c, $id ) = @_;
    my $project = $c->model('Schema::Project')->find($id);
    $c->session->{project} = $project->id;
    $c->response->redirect('/');
}

sub redirect : Private {
    my ( $self, $c, $id ) = @_;
    $c->response->redirect(
        $c->uri_for_action( $self->action_for('edit'), $id ) );
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
