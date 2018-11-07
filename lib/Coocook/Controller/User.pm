package Coocook::Controller::User;

use Data::Validate::Email 'is_email';
use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use feature 'fc';

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base : Chained('/base') PathPart('user') CaptureArgs(1) {
    my ( $self, $c, $name ) = @_;

    # this variable MUST NOT be named 'user' because it collides with $c->user
    # TODO maybe store $c->user as $c->stash->{logged_in_user} or similar
    #      and use $c->stash->{user} here?
    $c->stash( user_object => $c->model('DB::User')->find( { name_fc => fc($name) } )
          || $c->detach('/error/not_found') );

    # TODO redirect if case of $name doesn't match $user->name
}

sub show : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('view_user') {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user_object};

    my $permissions = $user->projects_users->search(
        undef,
        {
            prefetch => 'project',
            order_by => 'project.url_name_fc',
        }
    );

    $c->stash( permissions => \my @permissions );

    while ( my $permission = $permissions->next ) {
        my $project = $permission->project->as_hashref;

        $project->{url} = $c->uri_for_action( '/project/show', [ $project->{url_name} ] );

        push @permissions,
          {
            role    => $permission->role,
            project => $project,
          };
    }

    if ( $c->user and $c->user->id == $user->id ) {
        $c->stash( my_settings_url => $c->uri_for_action('/settings/index') );
    }

    $c->escape_title( User => $user->display_name );
}

sub register : GET HEAD Chained('/base') Args(0) {
    my ( $self, $c ) = @_;

    $c->user_registration_enabled
      or $c->detach('/error/forbidden');

    push @{ $c->stash->{js} }, qw<
      /js/user/register.js
      /lib/zxcvbn.js
    >;

    if ( my $terms = $c->model('DB::Terms')->valid_today ) {
        $c->stash(
            terms => $terms->as_hashref( url => $c->uri_for_action( '/terms/show', [ $terms->id ] ) ) );
    }

    $c->stash(
        example_username     => $c->config->{registration_example_username},
        example_display_name => $c->config->{registration_example_display_name},
        post_register_url    => $c->uri_for( $self->action_for('post_register') ),
    );
}

sub post_register : POST Chained('/base') PathPart('register') Args(0) {
    my ( $self, $c ) = @_;

    $c->user_registration_enabled
      or $c->detach('/error/forbidden');

    my $username     = $c->req->params->get('username');       # use key 'username' just like login form
    my $password     = $c->req->params->get('password');
    my $display_name = $c->req->params->get('display_name');
    my $email        = $c->req->params->get('email');

    my @errors;

    if ( length $username == 0 ) {
        push @errors, "username must not be empty";
    }
    elsif ( $username !~ m/ \A [0-9a-zA-Z_]+ \Z /x ) {
        push @errors, "username must not other characters than 0-9, a-z and A-Z.";
    }
    elsif ( $c->model('DB::User')->exists( { name_fc => fc($username) } ) ) {
        push @errors, "username already in use";
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

    my $terms = $c->model('DB::Terms')->valid_today;

    if ($terms) {
        my $id = $c->req->params->get('accept_terms')
          or $c->detach('/error/bad_request');    # parameter missing

        $id == $terms->id
          or push @errors, "you need accept the newest terms";    # invalid or outdated Terms id
    }

    if (@errors) {
        my $errors = $c->stash->{errors} ||= [];
        push @$errors, @errors;

        $c->stash(
            template   => 'user/register.tt',
            last_input => {
                username     => $username,
                display_name => $display_name,
                email        => $email,
            },
        );

        $c->go('register');
    }

    if ( my $user = $c->model('DB::User')->find( { email => $email } ) ) {
        $c->visit( '/email/email_address_reused' => [$user] );
    }
    else {    # e-mail address is unique
        my $token = $c->model('Token')->new();

        my $user = $c->model('DB::User')->create(
            {
                name         => $username,
                password     => $password,
                display_name => $c->req->params->get('display_name'),
                email        => $c->req->params->get('email'),
                token_hash   => $token->to_salted_hash,
                token_expires => undef,    # never: token only for verification, doesn't allow password reset
            }
        );

        # TODO this isn't secure in Perl. Is there any XS module for secure string erasure?
        $password = 'x' x length $password;
        undef $password;

        $c->visit( '/email/verification', [ $user, $token ] );

        $terms
          and $user->create_related(
            terms_users => {
                terms    => $terms->id,
                approved => $terms->format_datetime( DateTime->now ),
            }
          );

        my $site_admins_exist = $c->model('DB::RoleUser')->exists( { role => 'site_admin' } );

        if ( $site_admins_exist and $c->config->{notify_site_admins_about_registrations} ) {
            for my $admin ( $c->model('DB::User')->site_admins->all ) {
                $c->visit( '/email/notify_admin_about_registration' => [ $user, $admin ] );
            }
        }

        my @roles = @{ $c->config->{new_user_default_roles} || [] };

        $site_admins_exist
          or push @roles, 'site_admin';

        $user->add_roles( \@roles );
    }

    $c->redirect_detach(
        $c->uri_for(
            '/',
            {
                error => "You should receive an e-mail with a web link."
                  . " Please click that link to verify your e-mail address.",
            }
        )
    );
}

sub recover : GET HEAD Chained('/base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        email       => $c->req->params->get('email'),
        recover_url => $c->uri_for( $self->action_for('post_recover') ),
    );
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

sub reset_password : GET HEAD Chained('base') Args(1) {
    my ( $self, $c, $base64_token ) = @_;

    my $user = $c->stash->{user_object};

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

    my $user = $c->stash->{user_object};

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

    $c->visit( '/email/password_changed', [$user] );

    # no point in letting user log in again
    # https://security.stackexchange.com/q/64828/91275
    $c->set_authenticated( $c->find_user( { id => $user->id } ) );

    $c->response->redirect( $c->uri_for_action('/index') );
}

sub verify : GET HEAD Chained('base') PathPart('verify') Args(1) {
    my ( $self, $c, $base64_token ) = @_;

    my $user = $c->stash->{user_object};

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
