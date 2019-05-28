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

    $c->stash(
        name => $c->config->{name},
        view => 'Email',
    );
}

sub email_address_reused : Private {
    my ( $self, $c, $user ) = @_;

    $c->stash(
        email => {
            to       => $user->email,
            subject  => "Your e-mail address was registered at " . $c->config->{name},
            template => 'email_address_reused.tt',
        },
        user         => $user,
        recovery_url => $c->uri_for_action( '/user/recover', { email => $user->email } ),
    );
}

sub notify_admin_about_registration : Private {
    my ( $self, $c, $user, $admin ) = @_;

    $c->stash(
        email => {
            to       => $admin->email,
            subject  => sprintf( "New account '%s' registered at %s", $user->name, $c->config->{name} ),
            template => 'notify_admin_about_registration.tt',
        },
        admin => $admin,
        user  => $user,
    );
}

sub password_changed : Private {
    my ( $self, $c, $user ) = @_;

    $c->stash(
        email => {
            to       => $user->email,
            subject  => sprintf( "Your password at %s has changed", $c->config->{name} ),
            template => 'password_changed.tt',
        },
        user         => $user,
        recovery_url => $c->uri_for_action( '/user/recover', { email => $user->email } ),
    );
}

sub recovery_link : Private {
    my ( $self, $c, $user ) = @_;

    my $token   = $c->model('Token')->new();
    my $expires = DateTime->now->add( days => 1 );

    $user->update(
        {
            token_hash    => $token->to_salted_hash,
            token_expires => $user->format_datetime($expires),
        }
    );

    $c->stash(
        email => {
            to       => $user->email,
            subject  => "Account recovery at " . $c->config->{name},
            template => 'recovery_link.tt',
        },
        user         => $user,
        expires      => $expires,
        recovery_url => $c->uri_for_action( '/user/reset_password', [ $user->name, $token->to_base64 ] ),
    );
}

sub recovery_unregistered : Private {
    my ( $self, $c, $email ) = @_;

    $c->stash(
        email => {
            to       => $email,
            subject  => "Account recovery at " . $c->config->{name},
            template => 'recovery_unregistered.tt',
        },
        register_url => $c->uri_for_action('/user/register'),
    );
}

sub verification : Private {
    my ( $self, $c, $user, $token ) = @_;

    $c->stash(
        email => {
            to       => $user->email,
            subject  => "Verify your Account at " . $c->config->{name},
            template => 'verify.tt',
        },
        verification_url => $c->uri_for_action( '/user/verify', [ $user->name, $token->to_base64 ] ),
    );
}

sub end : Private {
    my ( $self, $c ) = @_;

    $c->stash->{email}{from} ||= sprintf '"%s" <%s>',
      $c->config->{email_sender_name},
      $c->config->{email_from_address};

    $c->forward( $c->view('Email') );
}

__PACKAGE__->meta->make_immutable;

1;
