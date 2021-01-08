package Test::Coocook;

use strict;
use warnings;
use open ':locale';    # respect encoding configured in terminal
use utf8;

our $DEBUG //= $ENV{TEST_COOCOOK_DEBUG};

use Carp;
use Email::Sender::Simple;
use FindBin;
use HTML::Meta::Robots;
use Regexp::Common 'URI';
use Scope::Guard qw< guard >;
use TestDB;
use Test::Most;

BEGIN {
    # don't actually send any emails
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';

    # point Catalyst to t/ to avoid reading local config files
    $ENV{COOCOOK_CONFIG} = "$FindBin::Bin";
}

# don't spill STDERR with info messages when not in verbose mode
our $DISABLE_LOG_LEVEL_INFO //= !$ENV{TEST_VERBOSE};

use parent 'Test::Coocook::Base';
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

sub clear_emails {
    my $self = shift;
    $self->{coocook_checked_email_count} = 0;
    Email::Sender::Simple->default_transport->clear_deliveries;
}

sub shift_emails {
    my $self = shift;
    my $n    = shift || 1;
    defined and $_ -= $n for $self->{coocook_checked_email_count};
    Email::Sender::Simple->default_transport->shift_deliveries for 1 .. $n;
}

sub email_count_is {
    my ( $self, $count, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->{coocook_checked_email_count} = $count;

    is(
        Email::Sender::Simple->default_transport->deliveries => $count,
        $name || sprintf( "%i emails stored", $count )
    );
}

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

        $self->text_like(qr/email/)
          or note $self->text;
    };
}

sub register_fails_like {
    my ( $self, $field_values, $error_regex, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $name || "register fails like '$error_regex'" => sub {
        $self->follow_link_ok( { text => 'Sign up' } );

        $self->submit_form_fails( { with_fields => $field_values },
            "register account '$$field_values{username}' ..." );

        $self->text_like($error_regex)
          or note $self->text;
    };
}

=head2 get_ok_email_link_like( qr/.../, "test name"? )

=head2 get_ok_email_link_like( qr/.../, $expected_status, "test name" )

Matches all URLs found in the email against the given regex
and calls C<get_ok()> on that URL.

=cut

sub get_ok_email_link_like {
    my $self            = shift;
    my $regex           = shift;
    my $name            = pop;
    my $expected_status = pop;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $name || "GET link from first email", sub {
        my $body = $self->_get_email_body();

        my @urls;

        while ( $body =~ m/$RE{URI}{HTTP}{ -scheme => 'https' }{-keep}/g ) {
            my $url = $1;    # can't match in list context because RE has groups

            $url =~ $regex
              and push @urls, $url;
        }

        if ( not is( scalar @urls => 1, "found 1 URL matching $regex" ) ) {
            note $body;
            return;
        }

        if ($expected_status) {
            $self->get( $urls[0] );
            $self->status_is(400);
        }
        else {
            $self->get_ok( $urls[0] );
        }
    };
}

sub email_like   { shift->_email_un_like( 1, @_ ) }
sub email_unlike { shift->_email_un_like( 0, @_ ) }

sub _email_un_like {
    my ( $self, $like, $regex, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 2;

    $name ||= "first email like $regex";

    my $body = $self->_get_email_body;

    if ( not defined $body ) {
        fail $name;
        return;
    }

    if ($like) {
        my @matches = ( $body =~ m/$regex/g );

        ok @matches >= 1, $name
          or note $body;

        return @matches;
    }
    else {
        my $ok = unlike( $body => $regex, $name )
          or note $body;

        return $ok;
    }
}

sub _get_email_body {
    my $self = shift;

    my $emails = $self->emails;

    if ( @$emails == 0 ) {
        carp "no emails stored";
        return;
    }

    my $checked = $self->{coocook_checked_email_count} || 1;

    {
        local $Carp::Internal{'Test::Coocook'} = 1;
        local $Carp::Internal{'Test::Builder'} = 1;
        local $Carp::Internal{'Test::More'}    = 1;

        @$emails > $checked
          and carp "More than 1 email stored";
    }

    my $email = $emails->[0]->{email};    # use first email

    return $email->get_body;
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
        my $logged_in = ( $self->text =~ m/settings Settings/ );

        if ($logged_in) {
            $self->follow_link_ok( { text => 'settings Settings' } );
            $self->follow_link_ok( { text => 'request a recovery link' } );
        }
        else {
            $self->follow_link_ok( { text => 'person Sign in' } );
            $self->follow_link_ok( { text => 'Lost your password?' } );
        }

        $self->submit_form_ok(
            {
                with_fields => {
                    email => $email,
                },
            },
            "submit email recovery form"
        );

        $self->text_contains('Recovery link sent')
          or note $self->text;

        $self->get_ok_email_link_like( qr/reset_password/, $name || "click email recovery link" );
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

sub checkbox_is_on  { shift->_checkbox_is_on_off( 1, @_ ) }
sub checkbox_is_off { shift->_checkbox_is_on_off( 0, @_ ) }

sub _checkbox_is_on_off {
    my ( $self, $expected, $input, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 2;

    my $value = $self->value($input);

    if ($expected) {
        is $value => 'on', $name || "checkbox '$input' is checked";
    }
    else {
        is $value => undef, $name || "checkbox '$input' is not checked";
    }
}

=head2 input_has_value($input, $value, $test_name?)

Finds input element with name C<$input> globally on the page (name must be unique)
and compares value to the expected C<$value>.

=cut

sub input_has_value {
    my ( $self, $input, $value, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @inputs = $self->find_all_inputs( name => $input );

    @inputs == 1
      or croak "More than 1 input element";

    is( $inputs[0]->value => $value, $name || "Input with name '$input' has value '$value'" )
      or note $self->content;
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

sub reload_ok {
    my $self = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok $self->reload(), "reload " . $self->base;
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

sub submit_form_fails {
    my ( $self, $params, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $res = $self->submit_form(%$params);

    if ( not $res ) {
        fail $name;
        return;
    }

    $self->status_is( 400, $name )
      or return;

    return $res;
}

1;
