package Coocook::Controller::Email;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

sub begin : Private {
    my ( $self, $c ) = @_;

    if ( my $signature = $c->config->{email_signature} ) {
        if ( ref $signature eq 'CODE' ) {
            $signature = $signature->($c);
        }

        $c->stash( signature => $signature );
    }

    $c->stash(
        name    => $c->config->{name},
        wrapper => 'email.tt',
    );
}

sub recovery_link : Private {
    my ( $self, $c, $user ) = @_;

    my $i       = 1;
    my $token   = 'TODO' . $i++;                     # TODO
    my $expires = DateTime->now->add( days => 1 );

    $user->update(
        {
            token         => $token,
            token_expires => $user->format_datetime($expires),
        }
    );

    $c->stash(
        email => {
            from     => 'coocook@example.com',                         # TODO configure
            to       => $user->email,
            subject  => "Account recovery at " . $c->config->{name},
            template => 'email/recovery_link.tt',
        },
        user         => $user,
        expires      => $expires,
        recovery_url => $c->uri_for_action( '/user/reset_password', [$token] ),
    );
}

sub recovery_unregistered : Private {
    my ( $self, $c, $email ) = @_;

    $c->stash(
        email => {
            from     => 'coocook@example.com',                         # TODO configure
            to       => $email,
            subject  => "Account recovery at " . $c->config->{name},
            template => 'email/recovery_unregistered.tt',
        },
        register_url => $c->uri_for_action('/user/register'),
    );
}

sub verification : Private {
    my ( $self, $c, $user ) = @_;

    $c->stash(
        email => {
            from     => 'coocook@example.com',                            # TODO configure
            to       => $user->email,
            subject  => "Verify your Account at " . $c->config->{name},
            template => 'email/verify.tt',
        },
        verification_url => $c->uri_for_action( '/user/verify', [ $user->token ] ),
    );
}

sub end : Private {
    my ( $self, $c ) = @_;

    $c->forward( $c->view('Email::Template') );
}

__PACKAGE__->meta->make_immutable;

1;
