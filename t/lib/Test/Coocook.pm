package Test::Coocook;

use strict;
use warnings;

use open ':locale';    # respect encoding configured in terminal

our $DEBUG //= $ENV{TEST_COOCOOK_DEBUG};

use Carp;
use Email::Sender::Simple;
use FindBin;
use HTML::Meta::Robots;
use Scope::Guard qw< guard >;
use TestDB;
use Test::Most;

BEGIN {
    # don't actually send any e-mails
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';

    # point Catalyst to t/ to avoid reading local config files
    $ENV{COOCOOK_CONFIG} = "$FindBin::Bin";
}

# don't spill STDERR with info messages when not in verbose mode
our $DISABLE_LOG_LEVEL_INFO //= !$ENV{TEST_VERBOSE};

use parent 'Test::WWW::Mechanize::Catalyst';

=head1 CONSTRUCTOR

=cut

sub new {
    my ( $class, %args ) = @_;

    defined( $args{deploy} ) && $args{schema}
      and croak "Can't use both arguments 'deploy' and 'schema'";

    my $config = delete $args{config};
    my $schema = delete $args{schema};

    my $deploy    = delete $args{deploy}    // 1;
    my $test_data = delete $args{test_data} // 1;

    my $self = $class->next::method(
        catalyst_app => 'Coocook',
        strict_forms => 1,           # change default to true
        %args
    );

    if ($DISABLE_LOG_LEVEL_INFO) {
        $self->catalyst_app->log->disable('info');
    }

    $schema //= TestDB->new( deploy => $deploy, test_data => $test_data );

    $self->catalyst_app->model('DB')->schema->storage( $schema->storage );

    $config
      and $self->reload_config($config);

    return $self;
}

=head1 METHODS

=cut

sub request {
    my $self = shift;
    my ($request) = @_;

    my $response = $self->next::method(@_);

    if ($DEBUG) {
        for ( [ '> ', $request ], [ '< ', $response ] ) {
            my ( $prefix, $message ) = @$_;

            note map { my $s = $_; $s =~ s/^/$prefix/gm; $s } $message->headers->as_string, "\n",
              ( $message->content_length > 0 ? $message->decoded_content : () );
        }
    }

    return $response;
}

sub emails {
    return [ Email::Sender::Simple->default_transport->deliveries ];
}

sub clear_emails { Email::Sender::Simple->default_transport->clear_deliveries }
sub shift_emails { Email::Sender::Simple->default_transport->shift_deliveries }

sub local_config_guard {
    my $self = shift;

    my $original_config = $self->catalyst_app->config;

    $self->reload_config(@_);

    return guard { $self->reload_config($original_config) };
}

sub reload_config {
    my $self = shift;

    my $app = $self->catalyst_app;

    $app->setup_finished(0);

    # Plugin::Static::Simple warns if $c->config->{static} exists
    # but creates this hash key itself in before(setup_finalize => sub {...})
    delete $app->config->{static};

    $app->config(@_);
    $app->setup_finalize();
}

sub schema { shift->catalyst_app->model('DB')->schema(@_) }

=head1 TEST METHODS

=cut

sub register_ok {
    my ( $self, $field_values, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $name || "register", sub {
        $self->follow_link_ok( { text => 'Sign up' } );

        $self->submit_form_ok( { with_fields => $field_values },
            "register account '$field_values->{username}'" );

        $self->text_like(qr/e-mail/)
          or note $self->text;
    };
}

sub register_fails_like {
    my ( $self, $field_values, $error_regex, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $name || "register fails like '$error_regex'" => sub {
        $self->follow_link_ok( { text => 'Sign up' } );

        note "Register account '$$field_values{username}' ...";
        $self->submit_form( with_fields => $field_values );

        $self->status_is(400) and $self->text_like($error_regex)
          or note $self->text;
    };
}

sub get_email_link_ok {
    my ( $self, $url_regex, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

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

sub email_like   { shift->_email_un_like( 1, @_ ) }
sub email_unlike { shift->_email_un_like( 0, @_ ) }

sub _email_un_like {
    my ( $self, $like, $regex, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $name ||= "first e-mail like $regex";

    my $emails = $self->emails;

    if ( @$emails == 0 ) {
        fail $name;
        diag "no e-mails stored";
        return;
    }

    @$emails > 1
      and carp "More than 1 e-mail stored";

    my $email = $emails->[0]->{email};    # use first e-mail

    note $email->as_string;

    my @matches = ( $email->get_body =~ m/$regex/g );

    if ($like) {
        ok @matches >= 1, $name;
        return @matches;
    }
    else {
        ok @matches == 0, $name;
    }
}

sub is_logged_in {
    my ( $self, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->text_contains( 'Settings', $name || "client is logged in" )
      or note $self->text;
}

sub is_logged_out {
    my ( $self, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->text_like( qr/Sign [Ii]n/, $name || "client is logged out" )
      or note $self->text;
}

sub login {
    my ( $self, $username, $password, %additional_fields ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->follow_link_ok( { text => 'person Sign in' } );

    $self->submit_form_ok(
        {
            with_fields => {
                username => $username,
                password => $password,
                %additional_fields
            },
        },
        "submit login form"
    );
}

=head2 $t->login_ok($username, $password, %additional_fields?, $name?)

=cut

sub login_ok {
    my $name = @_ % 2 ? undef : pop(@_);
    my ( $self, $username, $password, %additional_fields ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $name || "login with $username:$password", sub {
        my $orig_max_redirect = $self->max_redirect;
        $self->max_redirect(3);

        $self->login( $username, $password, %additional_fields );

        $self->is_logged_in();

        $self->max_redirect($orig_max_redirect);
    };
}

sub login_fails {
    my ( $self, $username, $password, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $name || "login with $username:$password fails", sub {
        $self->login( $username, $password );

        ( $self->text_like(qr/fail/) and $self->text_like(qr/Sign in/) )
          or note $self->text;
    };
}

sub logout_ok {
    my ( $self, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->click_ok( 'logout', $name || "click logout button" );
}

sub change_password_ok {
    my ( $self, $field_values, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $name || "change password", sub {
        $self->follow_link_ok( { text => 'settings Settings' } );

        $self->submit_form_ok( { with_fields => $field_values }, "submit change password form" );
    };
}

sub change_display_name_ok {
    my ( $self, $display_name, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $name || "change display name", sub {
        $self->follow_link_ok( { text => 'settings Settings' } );

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

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $name || "request recovery link for $email", sub {
        $self->follow_link_ok( { text => 'person Sign in' } );

        $self->follow_link_ok( { text => 'Lost your password?' } );

        $self->submit_form_ok(
            {
                with_fields => {
                    email => $email,
                },
            },
            "submit e-mail recovery form"
        );

        $self->text_contains('Recovery link sent')
          or note $self->text;
    };
}

sub reset_password_ok {
    my ( $self, $password, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

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

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $name || "reset password for $email to '$password'", sub {
        $self->request_recovery_link_ok($email);
        $self->reset_password_ok($password);
    };
}

sub create_project_ok {
    my ( $self, $fields, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $name || "create project '$fields->{name}'", sub {
        $self->get_ok('/');

        $self->submit_form_ok( { with_fields => $fields }, "submit create project form" );

        $self->text_contains( $fields->{name} )
          or note $self->text;
    };
}

sub redirect_is {
    my ( $self, $url, $expected, $status, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $name || "GET $url redirects $status $expected" => sub {
        my $original_max_redirect = $self->max_redirect();
        $self->max_redirect(0);

        ok $self->get($url), "GET $url";
        $self->status_is($status);
        $self->header_is( Location => $expected );

        $self->max_redirect($original_max_redirect);
    };
}

sub robots_flags_ok {
    my ( $self, $flags, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $name ||= "Response contains 'robots' meta tag with specified flags";

    my $fail = sub {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        fail $name;
        diag $_ for @_;
    };

    my @matches = ( $self->content =~ m/ <meta \s+ name="robots" \s+ content="([^"<>]*)"> /gx );

    if    ( @matches == 0 ) { return $fail->("Can't find 'robots' meta tag") }
    elsif ( @matches > 1 )  { return $fail->("Found more than 1 'robots' meta tag") }

    my $string = $matches[0];
    my $robots = HTML::Meta::Robots->new->parse($string);

    for ( sort keys %$flags ) {
        my ( $flag => $expected ) = ( $_ => $flags->{$_} );

        if ( $robots->$flag xor $expected ) {
            return $fail->(
                "Wrong value for flag '$flag'",
                "Found:    '$string'",
                "Expected: " . ( $expected ? "'$flag'" : "'no$flag'" )
            );
        }
    }

    pass $name;
}

sub status_is {
    my ( $self, $expected, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $ok = is $self->response->code => $expected,
      $name || sprintf(
        "Response code %i for %s %s",
        $expected,
        $self->response->request->method,
        $self->response->request->uri
      );

    if ( not $ok and $self->response->code =~ m/301|302|303|307|308/ ) {
        diag "Location: " . $self->response->header('Location');
    }

    return $ok;
}

sub status_like {
    my ( $self, $expected, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    like $self->response->code => $expected,
      $name || "Response has status code like '$expected'";
}

1;
