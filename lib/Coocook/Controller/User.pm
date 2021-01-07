package Coocook::Controller::User;

use feature 'fc';
use utf8;

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

    my $user = $c->model('DB::User')->find( { name_fc => fc($name) } )
      || $c->detach('/error/not_found');

    # this variable MUST NOT be named 'user' because it collides with $c->user
    # TODO maybe store $c->user as $c->stash->{logged_in_user} or similar
    #      and use $c->stash->{user} here?
    $c->stash( user_object => $user );

    $c->redirect_canonical_case( 0 => $user->name );
}

sub show : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('view_user') {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user_object};

    my @organizations = $user->organizations->sorted->hri->all;

    for my $organization (@organizations) {
        $organization->{url} = $c->uri_for_action( '/organization/show', [ $organization->{name} ] );
    }

    my @projects = $user->owned_projects->public->hri->all;

    for my $project (@projects) {
        $project->{url} = $c->uri_for_action( '/project/show', [ $project->{id}, $project->{url_name} ] );
    }

    if ( $c->user and $c->user->id == $user->id ) {
        $c->stash( my_settings_url => $c->uri_for_action('/settings/index') );
    }

    $c->stash(
        organizations     => \@organizations,
        projects          => \@projects,
        profile_admin_url => $c->uri_for_action_if_permitted( '/admin/user/show', [ $user->name ] ),
    );

    $c->stash->{robots}->archive(0);
}

sub register : GET HEAD Chained('/base') Args(0) Does('~HasCSS') Does('~HasJS') Public {
    my ( $self, $c ) = @_;

    if ( $c->user ) {    # user is already logged in, probably via other browser tab
        $c->detach('/_validated_redirect');
    }

    $c->user_registration_enabled
      or $c->detach('/error/forbidden');

    if ( not $c->model('DB::User')->results_exist ) {
        $c->messages->info( "There are currently no users registered at this Coocook installation."
              . " The first user you register will be site admin!" );

        $c->stash->{robots}->index(0);
    }

    # set register_form_served_epoch, except we're already in the progress and already have a timestamp
    for ( \$c->session->{register_form_served_epoch} ) {
        if ( $c->stash->{last_input} ) { $$_ ||= time }
        else                           { $$_ = time }
    }

    push @{ $c->stash->{js} }, '/lib/zxcvbn.js';

    if ( my $terms = $c->model('DB::Terms')->valid_today ) {
        $c->stash(
            terms => $terms->as_hashref( url => $c->uri_for_action( '/terms/show', [ $terms->id ] ) ) );
    }

    $c->stash(
        example_username  => $c->config->{registration_example_username},
        use_hidden_input  => $c->config->{captcha}{use_hidden_input},
        post_register_url => $c->redirect_uri_for_action( $self->action_for('post_register') ),
    );
}

sub post_register : POST Chained('/base') PathPart('register') Args(0) Public {
    my ( $self, $c ) = @_;

    $c->user_registration_enabled
      or $c->detach('/error/forbidden');

    my $username = $c->req->params->get('username');    # use key 'username' just like login form
    my $password = $c->req->params->get('password');
    my $email_fc = fc $c->req->params->get('email');

    my @errors;

    my $users = $c->model('DB::User');

    if ( length $username == 0 ) {
        push @errors, "username must not be empty";
    }
    elsif ( not $users->name_valid($username) ) {
        push @errors, "username must not contain other characters than 0-9, a-z, A-Z or _.";
    }
    elsif ( not $users->name_available($username) ) {
        push @errors, "username is not available";
    }

    if ( length $password == 0 ) {
        push @errors, "password must not be empty";
    }
    else {
        if ( $password ne $c->req->params->get('password2') ) {
            push @errors, "passwords don’t match";
        }
    }

    $c->model('DB::User')->email_valid_and_available($email_fc)
      or push @errors, "email address is invalid or already taken";

    my $terms = $c->model('DB::Terms')->valid_today;

    if ($terms) {
        my $id = $c->req->params->get('accept_terms')
          or $c->detach('/error/bad_request');    # parameter missing

        $id == $terms->id
          or push @errors, "you need accept the newest terms";    # invalid or outdated Terms id
    }

    # CAPTCHA only if no content errors above
    if ( @errors == 0 ) {
        my $robot = 0;                                            # expect the best

        if ( my $time_served = $c->session->{register_form_served_epoch} ) {
            my $timespan = time() - $time_served;

            if ( my $min = $c->config->{captcha}{form_min_time_secs} ) { $min <= $timespan or $robot++ }
            if ( my $max = $c->config->{captcha}{form_max_time_secs} ) { $timespan <= $max or $robot++ }
        }
        else {                                                    # form never served
            $robot++;
        }

        if ( $c->config->{captcha}{use_hidden_input} ) {
            length $c->req->params->get('url') > 0
              and $robot++;
        }

        $robot
          and push @errors, "We think you might be a robot. Please try again.";
    }

    if (@errors) {
        $c->messages->error($_) for @errors;

        $c->stash(
            template   => 'user/register.tt',
            last_input => {
                username => $username,
                email    => $email_fc,
            },
        );

        $c->res->status(400);

        $c->go('register');
    }

    my $token = $c->model('Token')->new();

    my $user = $c->model('DB::User')->create(
        {
            name          => $username,
            password      => $password,
            display_name  => $username,
            email_fc      => $email_fc,
            token_hash    => $token->to_salted_hash,
            token_expires => undef,    # never: token only for verification, doesn't allow password reset
        }
    );

    # TODO this isn't secure in Perl. Is there any XS module for secure string erasure?
    $password = 'x' x length $password;
    undef $password;

    $c->visit( '/email/verify', [ $user, $token ] );

    $terms
      and $user->create_related(
        terms_users => {
            terms_id => $terms->id,
            approved => $terms->format_datetime( DateTime->now ),
        }
      );

    my $site_owners_exist = $c->model('DB::RoleUser')->results_exist( { role => 'site_owner' } );

    if ( $site_owners_exist and $c->config->{notify_site_owners_about_registrations} ) {
        for my $admin ( $c->model('DB::User')->site_owners->all ) {
            $c->visit( '/email/notify_admin_about_registration' => [ $user, $admin ] );
        }
    }

    my @roles = @{ $c->config->{new_user_default_roles} || [] };

    $site_owners_exist
      or push @roles, 'site_owner';

    $user->add_roles( \@roles );

    $c->messages->info( "You should receive an email with a web link."
          . " Please click that link to verify your email address." );

    $c->redirect_detach( $c->uri_for('/') );
}

sub recover : GET HEAD Chained('/base') Args(0) Public {
    my ( $self, $c ) = @_;

    $c->stash(
        email       => $c->req->params->get('email'),
        recover_url => $c->uri_for( $self->action_for('post_recover') ),
    );
}

sub post_recover : POST Chained('/base') PathPart('recover') Args(0) Public {
    my ( $self, $c ) = @_;

    my $email_fc = fc $c->req->params->get('email');

    if ( not is_email($email_fc) ) {
        $c->messages->error("Enter a valid email address");

        $c->redirect_detach( $c->uri_for( $self->action_for('recover') ) );
    }

    if ( my $user = $c->model('DB::User')->find( { email_fc => $email_fc } ) ) {
        my $token   = $c->model('Token')->new();
        my $expires = DateTime->now->add( days => 1 );

        $user->update(
            {
                token_hash    => $token->to_salted_hash,
                token_expires => $user->format_datetime($expires),
                new_email_fc  => undef,                              # cancel email change, if in process
            }
        );

        $c->visit( '/email/recovery_link', [ $user, $token ] );
    }
    else {
        $c->visit( '/email/recovery_unregistered', [$email_fc] );
    }

    $c->messages->info("Recovery link sent");
    $c->response->redirect( $c->uri_for_action('/index') );
}

sub reset_password : GET HEAD Chained('base') Args(1) Public {
    my ( $self, $c, $base64_token ) = @_;

    my $user = $c->stash->{user_object};

    # accept only limited tokens
    # because password reset allows hijacking of valueable accounts
    if ( not( $user->token_expires and $user->check_base64_token($base64_token) ) ) {
        $c->messages->error("Your password reset link is invalid or expired!");

        $c->redirect_detach( $c->uri_for_action('/index') );
    }

    $c->stash( reset_password_url =>
          $c->uri_for( $self->action_for('post_reset_password'), [ $user->name, $base64_token ] ) );
}

sub post_reset_password : POST Chained('base') PathPart('reset_password') Args(1) Public {
    my ( $self, $c, $base64_token ) = @_;

    my $user = $c->stash->{user_object};

    # for rationale see reset_password()
    if ( not( $user->token_expires and $user->check_base64_token($base64_token) ) ) {
        $c->messages->error("Your password reset link is invalid or expired!");
        $c->detach('/error/bad_request');
    }

    my $new_password = $c->req->params->get('password');

    if ( $c->req->params->get('password2') ne $new_password ) {
        $c->messages->error("New passwords don’t match!");
        $c->redirect_detach(
            $c->uri_for( $self->action_for('reset_password'), [ $user->name, $base64_token ] ) );
    }

    $user->set_columns(
        {
            password      => $new_password,
            token_hash    => undef,
            token_expires => undef,
            token_created => undef,
        }
    );

    $user->email_verified
      or $user->email_verified( DateTime->now );

    $user->update();

    $c->visit( '/email/password_changed', [$user] );

    $c->messages->info("Your password has been changed.");

    # no point in letting user log in again
    # https://security.stackexchange.com/q/64828/91275
    $c->set_authenticated( $c->find_user( { id => $user->id } ) );

    $c->response->redirect( $c->uri_for_action('/index') );
}

sub verify : GET HEAD Chained('base') PathPart('verify') Args(1) Public {
    my ( $self, $c, $base64_token ) = @_;

    my $user = $c->stash->{user_object};

    if ( !$user->email_verified ) {

        # TODO better error message when user requested new password and then clicked link
        $user->check_base64_token($base64_token)
          or $c->detach('/error/bad_request');

        $user->update(
            {
                email_verified => $user->format_datetime( DateTime->now ),
                token_hash     => undef,
                token_expires  => undef,
            }
        );
    }

    $c->response->redirect( $c->uri_for_action( '/session/login', { username => $user->name } ) );
    $c->detach;
}

__PACKAGE__->meta->make_immutable;

1;
