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

    $c->stash( post_register_url => $c->uri_for( $self->action_for('post_register') ) );
}

sub post_register : POST Path('/register') Args(0) {
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

    my $token = join '', map { ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 )[ rand 26 + 26 + 10 ] } 1 .. 16;

    my $role = $c->model('DB::User')->count > 0 ? 'user' : 'admin';

    my $user = $c->model('DB::User')->create(
        {
            name          => $name,
            password_hash => $password,
            role          => $role,
            display_name  => scalar $c->req->param('display_name'),
            email         => scalar $c->req->param('email'),
            token         => $token,
            token_expires => undef,    # never: token only for verification, doesn't allow password reset
        }
    );

    $c->forward( '/email/verification', [$user] );

    $c->response->redirect( $c->uri_for('/') );
    $c->detach;
}

sub verify : GET Local Args(1) {
    my ( $self, $c, $token ) = @_;

    my $user = $c->model('DB::User')->find( { token => $token } );

    $user->email_verified
      or $user->update( { email_verified => $user->format_datetime( DateTime->now ) } );

    $c->response->redirect( $c->uri_for_action('/login') );
    $c->detach;
}

__PACKAGE__->meta->make_immutable;

1;
