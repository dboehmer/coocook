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

sub register : GET Path('/register') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( register_url => $c->uri_for( $self->action_for('create') ) );
}

sub create : POST Path('/users/create') Args(0) {
    my ( $self, $c ) = @_;

    my $password = $c->req->param('password');

    $password eq $c->req->param('password2')
      or die "passwords don't match";    # TODO error message

    my $user = $c->model('DB::User')->create(
        {
            name         => scalar $c->req->param('name'),
            display_name => scalar $c->req->param('display_name'),
            email        => scalar $c->req->param('email'),
            password     => $password,
        }
    );

    $c->set_authenticated(               # TODO documented as internal method
        $c->find_user( { id => $user->id } )
    );

    $c->response->redirect( $c->uri_for('/') );
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
