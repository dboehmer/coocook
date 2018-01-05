package Coocook::Controller::User;

use Data::Validate::Email 'is_email';
use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

Coocook::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base : Chained('/enforce_ssl') PathPart('user') CaptureArgs(1) {
    my ( $self, $c, $name ) = @_;

    $c->stash( user => $c->model('DB::User')->find( { name => $name } ) );
}

sub show : GET Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user};

    my @permissions = $user->projects_users->search(
        undef,
        {
            prefetch => 'project',
            order_by => 'project.url_name_fc',
        }
    )->all;

    $c->stash( permissions => \@permissions );

    $c->escape_title( User => $user->display_name );
}

sub register : GET Chained('/enforce_ssl') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( post_register_url => $c->uri_for( $self->action_for('post_register') ) );
}

sub post_register : POST Chained('/enforce_ssl') PathPart('register') Args(0) {
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
            name         => $name,
            password     => $password,
            role         => $role,
            display_name => scalar $c->req->param('display_name'),
            email        => scalar $c->req->param('email'),
            token        => $token,
            token_expires => undef,    # never: token only for verification, doesn't allow password reset
        }
    );

    $c->visit( '/email/verification', [$user] );

    $c->response->redirect( $c->uri_for('/') );
    $c->detach;
}

sub recover : GET Chained('/enforce_ssl') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( recover_url => $c->uri_for( $self->action_for('post_recover') ) );
}

sub post_recover : POST Chained('/enforce_ssl') PathPart('recover') Args(0) {
    my ( $self, $c ) = @_;

    my $email = $c->req->param('email');

    if ( !is_email($email) ) {
        $c->response->redirect(
            $c->uri_for( $self->action_for('recover'), { error => "Enter a valid e-mail address" } ) );
        $c->detach;
    }

    if ( my $user = $c->model('DB::User')->find( { email => $email } ) ) {
        $c->visit( '/email/recovery_link', [$user] );
    }
    else {
        $c->visit( '/email/recovery_unregistered', [$email] );
    }

    $c->response->redirect( $c->uri_for_action( '/index', { error => "Recovery link sent" } ) );
}

sub reset_password : GET Chained('/enforce_ssl') Args(1) {
    my ( $self, $c, $token ) = @_;

    my $user = $c->forward( _find_user_by_token => [$token] )
      or die;

    $c->stash( reset_password_url => $c->uri_for( $self->action_for('post_reset_password'), $token ) );
}

sub post_reset_password : POST Chained('/enforce_ssl') PathPart('reset_password') Args(1) {
    my ( $self, $c, $token ) = @_;

    my $new_password = $c->req->param('password');

    $c->req->param('password2') eq $new_password
      or die "new passwords don't match";    # TODO error handling

    my $user = $c->forward( _find_user_by_token => [$token] )
      or die;

    $user->update(
        {
            password      => $new_password,
            token         => undef,
            token_expires => undef,
        }
    );

    # no point in letting user log in again
    # https://security.stackexchange.com/q/64828/91275
    $c->set_authenticated( $c->find_user( { id => $user->id } ) );

    $c->response->redirect( $c->uri_for_action('/index') );
}

sub verify : GET Chained('/enforce_ssl') PathPart('user/verify') Args(1) {
    my ( $self, $c, $token ) = @_;

    my $user = $c->forward( _find_user_by_token => [$token] )
      or die;

    $user->email_verified
      or $user->update( { email_verified => $user->format_datetime( DateTime->now ) } );

    $c->response->redirect( $c->uri_for_action('/login') );
    $c->detach;
}

sub _find_user_by_token : Private {
    my ( $self, $c, $token ) = @_;

    my $users = $c->model('DB::User');

    my $user = $users->find(
        { token => $token, token_expires => { '>' => $users->format_datetime( DateTime->now ) } } )
      or die "no token or token expired";    # TODO error handling

    return $user;
}

__PACKAGE__->meta->make_immutable;

1;
