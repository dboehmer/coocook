package Coocook::Controller::Email::ChangeEmail;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

# Catalyst compiles ChangeEmail into changeemail
__PACKAGE__->config( namespace => 'email/change_email' );

sub to_current_email : Private {
    my ( $self, $c, $user ) = @_;

    $c->stash(
        email                => { to => $user->email_fc },
        user                 => $user,
        current_email        => $user->email_fc,
        new_email            => $user->new_email_fc,
        expires              => $user->token_expires,
        account_settings_url => $c->uri_for_action('/settings/account'),
    );
}

sub to_new_email : Private {
    my ( $self, $c, $user, $token ) = @_;

    $c->stash(
        email            => { to => $user->new_email_fc },
        user             => $user,
        current_email    => $user->email_fc,
        new_email        => $user->new_email_fc,
        verification_url => $c->uri_for_action( '/settings/change_email/verify', [ $token->to_base64 ] ),
    );
}

__PACKAGE__->meta->make_immutable;

1;
