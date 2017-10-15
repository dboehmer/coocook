package Coocook::Controller::User;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

Coocook::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base : Chained('/') PathPart('user') CaptureArgs(1) {
    my ( $self, $c, $name ) = @_;

    $c->stash( user => $c->model('DB::User')->find( { name => $name } ) );
}

sub show : GET Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user};

    $c->stash( projects => [ $user->projects->all ] );

    $c->escape_title( User => $user->display_name );
}

sub update : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user};

    $user->update(
        {
            display_name => scalar $c->req->param('display_name'),
        }
    );

    $c->response->redirect( $c->uri_for( $self->action_for('show'), [ $user->name ] ) );
}

__PACKAGE__->meta->make_immutable;

1;
