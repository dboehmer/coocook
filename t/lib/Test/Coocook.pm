package Test::Coocook;

use strict;
use warnings;

use Email::Sender::Simple;
use FindBin;
use Test::Most;

BEGIN {
    # don't actually send any e-mails
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';

    # point Catalyst to t/ to avoid reading local config files
    $ENV{COOCOOK_CONFIG} = "$FindBin::Bin";
}

use parent 'Test::WWW::Mechanize::Catalyst';

sub new {
    my $class = shift;

    return $class->SUPER::new( catalyst_app => 'Coocook', @_ );
}

sub emails {
    return [ Email::Sender::Simple->default_transport->deliveries ];
}

sub clear_emails {
    Email::Sender::Simple->default_transport->clear_deliveries;
}

sub register_ok {
    my ( $self, $field_values, $name ) = @_;

    subtest $name || "register", sub {
        $self->follow_link_ok( { text => 'Register' } );

        $self->submit_form_ok(
            {
                with_fields  => $field_values,
                strict_forms => 1,
            },
            "register account"
        );

        $self->content_like(qr/e-mail/)
          or note $self->content;
    };
}

sub get_email_link_ok {
    my ( $self, $url_regex, $name ) = @_;

    subtest $name || "GET link from last e-mail", sub {
        my $emails = $self->emails;

        if ( @$emails == 0 ) {
            fail "no e-mails stored";
        }
        else {
            @$emails > 1
              and warn "More than 1 e-mail stored";

            my $email = $emails->[-1]->{email};    # use last e-mail

            note $email->as_string;

            my @urls = ( $email->get_body =~ m/$url_regex/g );

            is scalar @urls => 1,
              "found 1 URL"
              or return;

            my $verification_url = $urls[0];

            $self->get_ok($verification_url);
        }
    };
}

sub verify_email_ok {
    my ( $self, $name ) = @_;

    $self->get_email_link_ok(
        qr/http\S+verify\S+/,    # TODO regex is very simple and will break easily
        $name || "verify e-mail address"
    );
}

sub is_logged_in {
    my ( $self, $name ) = @_;

    $self->content_like( qr/Dashboard/, $name || "client is logged in" )
      or note $self->content;
}

sub login {
    my ( $self, $username, $password ) = @_;

    $self->follow_link_ok( { text => 'Login' } );

    $self->submit_form_ok(
        {
            with_fields => {
                username => $username,
                password => $password,
            },
            strict_forms => 1,
        },
        "submit login form"
    );
}

sub login_ok {
    my ( $self, $username, $password, $name ) = @_;

    subtest $name || "login with $username:$password", sub {
        $self->login( $username, $password );

        $self->is_logged_in();
    };
}

sub login_fails {
    my ( $self, $username, $password, $name ) = @_;

    subtest $name || "login with $username:$password fails", sub {
        $self->login( $username, $password );

        ( $self->content_like(qr/fail/) and $self->content_like(qr/Login/) )
          or note $self->content;
    };
}

sub logout_ok {
    my ( $self, $name ) = @_;

    subtest $name || "logout", sub {
        $self->get_ok('/');    # TODO enable logout from all pages

        $self->click_ok( 'logout', "click logout button" );
    };
}

sub change_password_ok {
    my ( $self, $field_values, $name ) = @_;

    subtest $name || "change password", sub {
        $self->follow_link_ok( { text => 'Settings' } );

        $self->submit_form_ok(
            {
                with_fields  => $field_values,
                strict_forms => 1,
            },
            "submit change password form"
        );
    };
}

sub change_display_name_ok {
    my ( $self, $display_name, $name ) = @_;

    subtest $name || "change display name", sub {
        $self->follow_link_ok( { text => 'Settings' } );

        $self->submit_form_ok(
            {
                with_fields  => { display_name => $display_name },
                strict_forms => 1,
            },
            "submit change display name form"
        );
    };
}

sub request_recovery_link_ok {
    my ( $self, $email, $name ) = @_;

    subtest $name || "request recovery link for $email", sub {
        $self->follow_link_ok( { text => 'Login' } );

        $self->follow_link_ok( { text => 'Lost your password?' } );

        $self->submit_form_ok(
            {
                with_fields  => { email => $email },
                strict_forms => 1,
            },
            "submit e-mail recovery form"
        );

        $self->content_contains('Recovery link sent')
          or note $self->content;
    };
}

sub reset_password_ok {
    my ( $self, $password, $name ) = @_;

    subtest $name || "reset password to '$password'", sub {
        $self->get_email_link_ok(
            qr/http\S+reset_password\S+/,    # TODO regex is very simple and will break easily
            $name || "click e-mail recovery link"
        );

        $self->submit_form_ok(
            {
                with_fields => {
                    password  => $password,
                    password2 => $password,
                },
                strict_forms => 1,
            },
            "submit password reset form"
        );
    };
}

sub recover_account_ok {
    my ( $self, $email, $password, $name ) = @_;

    subtest $name || "reset password for $email to '$password'", sub {
        $self->request_recovery_link_ok($email);
        $self->reset_password_ok($password);
    };
}

sub create_project_ok {
    my ( $self, $fields, $name ) = @_;

    subtest $name || "create project '$fields->{name}'", sub {
        $self->get_ok('/');

        $self->submit_form_ok(
            {
                with_fields  => $fields,
                strict_forms => 1,
            },
            "submit create project form"
        );

        $self->content_contains( $fields->{name} )
          or note $self->content;
    };
}

1;