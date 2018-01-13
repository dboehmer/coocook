package Coocook::Controller::User;

use Data::Validate::Email 'is_email';
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

sub show : GET Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user};

    $c->stash( projects => [ $user->projects->all ] );

    $c->escape_title( User => $user->display_name );
}

sub register : GET Path('/register') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( register_url => $c->uri_for( $self->action_for('create') ) );
}

sub create : POST Path('/register') Args(0) {
    my ( $self, $c ) = @_;

    my $name         = $c->req->param('name');
    my $password     = $c->req->param('password');
    my $display_name = $c->req->param('display_name');
    my $email        = $c->req->param('email');

    my @errors;

    if ( length $name == 0 ) {
        push @errors, "username must not be empty";
    }
    else {
        if ( $c->model('DB::User')->search( { name => $name } )->count > 0 ) {    # TODO case sensitivity?
            push @errors, "username already in use";
        }
    }

    if ( length $password == 0 ) {
        push @errors, "password must not be empty";
    }
    else {
        if ( $password ne $c->req->param('password2') ) {
            push @errors, "password's don't match";
        }
    }

    if ( length $display_name == 0 ) {
        push @errors, "display name must not be empty";
    }

    $email = is_email($email)
      or push @errors, "e-mail address is not valid";

    if (@errors) {
        my $errors = $c->stash->{errors} ||= [];
        push @$errors, @errors;

        $c->stash(
            template   => 'user/register.tt',
            last_input => {
                name         => $name,
                display_name => $display_name,
                email        => $email,
            },
        );

        $c->go('register');
    }

    my $user = $c->model('DB::User')->create(
        {
            name         => $name,
            password     => $password,
            display_name => scalar $c->req->param('display_name'),
            email        => scalar $c->req->param('email'),
        }
    );

    $c->set_authenticated(    # TODO documented as internal method
        $c->find_user( { id => $user->id } )
    );

    $c->response->redirect( $c->uri_for('/') );
    $c->detach;
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
