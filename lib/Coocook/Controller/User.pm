package Coocook::Controller::User;

use Data::Validate::Email 'is_email';
use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base : Chained('/base') PathPart('user') CaptureArgs(1) {
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

sub register : GET Chained('/base') Args(0) {
    my ( $self, $c ) = @_;

    $c->user_registration_enabled
      or $c->detach('/error/forbidden');

    push @{ $c->stash->{js} }, qw<
      js/user/register.js
      lib/zxcvbn.js
    >;

    $c->stash( post_register_url => $c->uri_for( $self->action_for('post_register') ) );
}

sub post_register : POST Chained('/base') PathPart('register') Args(0) {
    my ( $self, $c ) = @_;

    $c->user_registration_enabled
      or $c->detach('/error/forbidden');

    my $name         = $c->req->params->get('name');
    my $password     = $c->req->params->get('password');
    my $display_name = $c->req->params->get('display_name');
    my $email        = $c->req->params->get('email');

    my @errors;

    if ( length $name == 0 ) {
        push @errors, "username must not be empty";
    }
    else {
        if ( $c->model('DB::User')->exists( { name => $name } ) ) {    # TODO case sensitivity?
            push @errors, "username already in use";
        }
    }

    if ( length $password == 0 ) {
        push @errors, "password must not be empty";
    }
    else {
        if ( $password ne $c->req->params->get('password2') ) {
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

    my $token = $c->model('Token')->new();

    my $is_1st_user = !$c->model('DB::User')->exists;

    my $user = $c->model('DB::User')->create(
        {
            name         => $name,
            password     => $password,
            display_name => $c->req->params->get('display_name'),
            email        => $c->req->params->get('email'),
            token_hash   => $token->to_salted_hash,
            token_expires => undef,    # never: token only for verification, doesn't allow password reset
        }
    );

    $user->add_roles( $c->config->{new_user_default_roles} );

    if ($is_1st_user) {
        $user->add_roles('site_admin');
    }

    $c->visit( '/email/verification', [ $user, $token ] );

    $c->redirect_detach( $c->uri_for('/') );
}

sub recover : GET Chained('/base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( recover_url => $c->uri_for( $self->action_for('post_recover') ) );
}

sub post_recover : POST Chained('/base') PathPart('recover') Args(0) {
    my ( $self, $c ) = @_;

    my $email = $c->req->params->get('email');

    is_email($email)
      or $c->redirect_detach(
        $c->uri_for( $self->action_for('recover'), { error => "Enter a valid e-mail address" } ) );

    if ( my $user = $c->model('DB::User')->find( { email => $email } ) ) {
        $c->visit( '/email/recovery_link', [$user] );
    }
    else {
        $c->visit( '/email/recovery_unregistered', [$email] );
    }

    $c->response->redirect( $c->uri_for_action( '/index', { error => "Recovery link sent" } ) );
}

sub reset_password : GET Chained('base') Args(1) {
    my ( $self, $c, $base64_token ) = @_;

    my $user = $c->stash->{user};

    # accept only limited tokens
    # because password reset allows hijacking of valueable accounts
    ( $user->token_expires and $user->check_base64_token($base64_token) )
      or $c->redirect_detach(
        $c->uri_for_action( '/index', { error => "Your password reset link is invalid or expired!" } ) );

    $c->stash( reset_password_url =>
          $c->uri_for( $self->action_for('post_reset_password'), [ $user->name, $base64_token ] ) );
}

sub post_reset_password : POST Chained('base') PathPart('reset_password') Args(1) {
    my ( $self, $c, $base64_token ) = @_;

    my $user = $c->stash->{user};

    # for rationale see reset_password()
    ( $user->token_expires and $user->check_base64_token($base64_token) )
      or die;

    my $new_password = $c->req->params->get('password');

    $c->req->params->get('password2') eq $new_password
      or die "new passwords don't match";    # TODO error handling

    $user->set_columns(
        {
            password      => $new_password,
            token_hash    => undef,
            token_expires => undef,
        }
    );

    $user->email_verified
      or $user->email_verified( DateTime->now );

    $user->update();

    # no point in letting user log in again
    # https://security.stackexchange.com/q/64828/91275
    $c->set_authenticated( $c->find_user( { id => $user->id } ) );

    $c->response->redirect( $c->uri_for_action('/index') );
}

sub verify : GET Chained('base') PathPart('verify') Args(1) {
    my ( $self, $c, $base64_token ) = @_;

    my $user = $c->stash->{user};

    if ( !$user->email_verified ) {
        $user->check_base64_token($base64_token)
          or die;    # TODO error handling

        $user->update(
            {
                email_verified => $user->format_datetime( DateTime->now ),
                token_hash     => undef,
                token_expires  => undef,
            }
        );
    }

    $c->response->redirect( $c->uri_for_action( '/login', { username => $user->name } ) );
    $c->detach;
}

__PACKAGE__->meta->make_immutable;

1;
