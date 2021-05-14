package Coocook::Controller::Email;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub begin : Private {
    my ( $self, $c ) = @_;

    if ( my $signature = $c->config->{email_signature} ) {
        if ( ref $signature eq 'CODE' ) {
            $signature = $signature->($c);
        }

        $c->stash( signature => $signature );
    }

    $c->stash( current_view => 'Email' );
}

sub notify_admin_about_registration : Private {
    my ( $self, $c, $user, $admin ) = @_;

    my $email_anonymized = $user->email_fc;
    $email_anonymized =~ s/ ^ .+ \@ /***@/x;

    $c->stash(
        email            => { to => $admin->email_fc },
        admin            => $admin,
        email_anonymized => $email_anonymized,
        user             => $user,
        user_url         => $c->uri_for_action( '/user/show',       [ $user->name ] ),
        user_admin_url   => $c->uri_for_action( '/admin/user/show', [ $user->name ] ),
    );
}

sub password_changed : Private {
    my ( $self, $c, $user ) = @_;

    $c->stash(
        email        => { to => $user->email_fc },
        user         => $user,
        recovery_url => $c->uri_for_action( '/user/recover', { email => $user->email_fc } ),
    );
}

sub recovery_link : Private {
    my ( $self, $c, $user, $token ) = @_;

    $c->stash(
        email        => { to => $user->email_fc },
        user         => $user,
        expires      => $user->token_expires,
        recovery_url => $c->uri_for_action( '/user/reset_password', [ $user->name, $token->to_base64 ] ),
    );
}

sub recovery_unregistered : Private {
    my ( $self, $c, $email ) = @_;

    $c->stash(
        email        => { to => $email },
        register_url => $c->uri_for_action('/user/register'),
    );
}

sub verify : Private {
    my ( $self, $c, $user, $token ) = @_;

    $c->stash(
        email            => { to => $user->email_fc },
        verification_url => $c->uri_for_action( '/user/verify', [ $user->name, $token->to_base64 ] ),
        user             => $user,
    );
}

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;

    $c->stash->{email}{from} ||= sprintf '"%s" <%s>',
      $c->config->{email_sender_name},
      $c->config->{email_from_address};
}

__PACKAGE__->meta->make_immutable;

1;
