package Test::Coocook;

use strict;
use warnings;

our $DEBUG;

use Email::Sender::Simple;
use FindBin;
use Test::Most;

BEGIN {
    # don't actually send any e-mails
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';

    # point Catalyst to t/ to avoid reading local config files
    $ENV{COOCOOK_CONFIG} = "$FindBin::Bin";
}

# don't spill STDERR with info messages when not in verbose mode
our $DISABLE_LOG_LEVEL_INFO //= !$ENV{TEST_VERBOSE};

use Coocook;

*Coocook::reload_config = sub {
    my $class = shift;

    $class->setup_finished(0);

    # Plugin::Static::Simple warns if $c->config->{static} exists
    # but creates this hash key itself in before(setup_finalize => sub {...})
    delete $class->config->{static};

    $class->config(@_);
    $class->setup_finalize();
};

use parent 'Test::WWW::Mechanize::Catalyst';

sub new {
    my ( $class, %args ) = @_;

    my $schema = delete $args{schema};

    my $self = $class->SUPER::new(
        catalyst_app => 'Coocook',
        strict_forms => 1,           # change default to true
        %args
    );

    if ($DISABLE_LOG_LEVEL_INFO) {
        $self->catalyst_app->log->disable('info');
    }

    if ($schema) {
        $self->catalyst_app->model('DB')->schema->storage( $schema->storage );
    }

    return $self;
}

sub request {
    my $self = shift;
    my ($request) = @_;

    my $response = $self->SUPER::request(@_);

    if ($DEBUG) {
        note map { s/^/> /gm; $_ } $request->as_string;
        note map { s/^/< /gm; $_ } $response->as_string;
    }

    return $response;
}

sub emails {
    return [ Email::Sender::Simple->default_transport->deliveries ];
}

sub clear_emails { Email::Sender::Simple->default_transport->clear_deliveries }
sub shift_emails { Email::Sender::Simple->default_transport->shift_deliveries }

sub register_ok {
    my ( $self, $field_values, $name ) = @_;

    subtest $name || "register", sub {
        $self->follow_link_ok( { text => 'Sign up' } );

        $self->submit_form_ok( { with_fields => $field_values },
            "register account '$field_values->{username}'" );

        $self->content_like(qr/e-mail/)
          or note $self->content;
    };
}

sub get_email_link_ok {
    my ( $self, $url_regex, $name ) = @_;

    subtest $name || "GET link from first e-mail", sub {
        my @urls = $self->email_like($url_regex);

        is scalar @urls => 1,
          "found 1 URL"
          or return;

        my $verification_url = $urls[0];

        $self->get_ok($verification_url);
    };
}

sub verify_email_ok {
    my ( $self, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->get_email_link_ok(
        qr/http\S+verify\S+/,    # TODO regex is very simple and will break easily
        $name || "verify e-mail address"
    );
}

sub email_like {
    my ( $self, $regex, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $name ||= "first e-mail like $regex";

    my $emails = $self->emails;

    if ( @$emails == 0 ) {
        fail $name;
        diag "no e-mails stored";
        return;
    }

    @$emails > 1
      and warn "More than 1 e-mail stored";

    my $email = $emails->[0]->{email};    # use first e-mail

    note $email->as_string;

    my @matches = ( $email->get_body =~ m/$regex/g );

    ok @matches >= 1, $name;

    return @matches;
}

sub is_logged_in {
    my ( $self, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->content_like( qr/Account [Ss]ettings/, $name || "client is logged in" )
      or note $self->content;
}

sub is_logged_out {
    my ( $self, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->content_like( qr/Sign [Ii]n/, $name || "client is logged out" )
      or note $self->content;
}

sub login {
    my ( $self, $username, $password ) = @_;

    $self->follow_link_ok( { text => 'Sign in' } );

    $self->submit_form_ok(
        {
            with_fields => {
                username => $username,
                password => $password,
            },
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

        ( $self->content_like(qr/fail/) and $self->content_like(qr/Sign in/) )
          or note $self->content;
    };
}

sub logout_ok {
    my ( $self, $name ) = @_;

    $self->click_ok( 'logout', $name || "click logout button" );
}

sub change_password_ok {
    my ( $self, $field_values, $name ) = @_;

    subtest $name || "change password", sub {
        $self->follow_link_ok( { text => 'Account Settings' } );

        $self->submit_form_ok( { with_fields => $field_values }, "submit change password form" );
    };
}

sub change_display_name_ok {
    my ( $self, $display_name, $name ) = @_;

    subtest $name || "change display name", sub {
        $self->follow_link_ok( { text => 'Account Settings' } );

        $self->submit_form_ok(
            {
                with_fields => {
                    display_name => $display_name,
                },
            },
            "submit change display name form"
        );
    };
}

sub request_recovery_link_ok {
    my ( $self, $email, $name ) = @_;

    subtest $name || "request recovery link for $email", sub {
        $self->follow_link_ok( { text => 'Sign in' } );

        $self->follow_link_ok( { text => 'Lost your password?' } );

        $self->submit_form_ok(
            {
                with_fields => {
                    email => $email,
                },
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

        $self->submit_form_ok( { with_fields => $fields }, "submit create project form" );

        $self->content_contains( $fields->{name} )
          or note $self->content;
    };
}

sub status_is {
    my ( $self, $expected, $name ) = @_;

    is $self->response->code => $expected,
      $name || "Response has status code $expected";
}

1;
