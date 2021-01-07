package Coocook::Controller::Settings::ChangeEmail;

use feature 'fc';
use utf8;

use Data::Validate::Email 'is_email';
use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

# Catalyst compiles ChangeEmail into changeemail
__PACKAGE__->config( namespace => 'settings/change_email' );

sub base : Chained('/settings/base') PathPart('change_email') CaptureArgs(0) { }

sub request : POST Chained('base') PathPart('') Args(0) RequiresCapability('change_email') {
    my ( $self, $c ) = @_;

    my $email = $c->req->params->get('new_email')
      or $c->detach('/error/bad_request');

    my $email_fc = fc $email;

    if ( $email_fc eq $c->user->email_fc ) {
        $c->messages->info( $email_fc . " is already your current email address." );
        $c->redirect_detach( $c->uri_for_action('/settings/account') );
    }

    my $user = $c->user;

    # TODO show input page again with input kept
    $c->model('DB::User')->email_valid_and_available($email)
      or $c->detach( '/error/bad_request', ["email address is invalid or already taken"] );

    my $token   = $c->model('Token')->new();
    my $expires = DateTime->now->add( days => 1 );

    $user->update(
        {
            new_email_fc  => $email_fc,
            token_hash    => $token->to_salted_hash,
            token_expires => $user->format_datetime($expires),
            token_created => $user->format_datetime_now,
        }
    );

    $c->visit( '/email/change_email/to_current_email', [ $c->user ] );
    $c->visit( '/email/change_email/to_new_email',     [ $c->user, $token ] );

    $c->messages->info( "You’ve received emails to both your old and your new email address."
          . " Click the verification link sent to the new address to complete the change" );

    $c->detach('redirect');
}

sub verify : GET HEAD Chained('base') Args(1) RequiresCapability('change_email') {
    my ( $self, $c, $base64_token ) = @_;

    my $user = $c->user;

    $user->check_base64_token($base64_token)
      or $c->detach('/error/bad_request');

    $c->stash(
        confirm_email_change_url => $c->uri_for( $self->action_for('post_verify'), [$base64_token] ) );

    $c->go('/settings/account');
}

sub post_verify : POST Chained('base') Args(1) RequiresCapability('change_email') {
    my ( $self, $c, $base64_token ) = @_;

    my $user = $c->user;

    $user->check_base64_token($base64_token)
      or $c->detach('/error/bad_request');

    $user->update(
        {
            email_fc      => $user->new_email_fc,
            new_email_fc  => undef,
            token_hash    => undef,
            token_created => undef,
            token_expires => undef,
        }
    );

    $c->messages->info( "Your email address was successfully changed to " . $user->email_fc );

    $c->detach('redirect');
}

sub cancel : POST Chained('base') Args(0) RequiresCapability('change_email') {
    my ( $self, $c ) = @_;

    my $user = $c->user;

    $user->new_email_fc and $user->token_hash
      or $c->detach('/error/bad_request');

    my $new_email_fc = $user->new_email_fc;

    $user->update(
        {    # email_fc MUST NOT be changed here!
            new_email_fc  => undef,
            token_hash    => undef,
            token_created => undef,
            token_expires => undef,
        }
    );

    $c->messages->info( sprintf "The change of your email address to %s has been cancelled.",
        $new_email_fc );

    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->redirect_detach( $c->uri_for_action('/settings/account') );
}

1;
