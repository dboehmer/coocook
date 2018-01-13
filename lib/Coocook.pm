package Coocook;

# ABSTRACT: Web application for collecting recipes and making food plans
# VERSION

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst (
    qw<
      ConfigLoader
      Session
      Session::Store::DBIC
      Session::State::Cookie
      Authentication
      Static::Simple
      >,
    ( eval "require Catalyst::Plugin::StackTrace; 1" ? 'StackTrace' : () ),
);

extends 'Catalyst';

with 'Coocook::Helpers';

if ( $ENV{CATALYST_DEBUG} ) {
    if ( eval "require CatalystX::LeakChecker; 1" ) {
        with 'CatalystX::LeakChecker';
    }

    # print e-mails on STDOUT in debugging mode
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Print';

    __PACKAGE__->config(
        require_ssl => {
            disabled       => 1,
            ignore_on_post => 1,    # 'disabled' seems not to apply to POST requests
        },
    );
}

# Configure the application.
#
# Note that settings in coocook.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'Coocook',

    # reasoning: if tab title bar in browser is short,
    #            display most important information first
    date_format_short => '%a, %{day} %b',    # Mon, 31 Dec

    # based on
    # https://en.wikipedia.org/w/index.php?title=Calendar_date&oldid=799176855
    date_format_long => '%A, %{day} %B %Y',    # Monday, 31 December 2001

    new_user_default_roles => [
        'private_projects',                    # disable to prohibit new users creating private projects
    ],

    homepage_text_md => do {    # Markdown text for homepage, default: abstract of Coocook.pm
        open my $fh, '<', __FILE__;    # read abstract from this file
        my $abstract;
        while (<$fh>) {
            /^# ?ABSTRACT: (.+)$/ or next;
            $abstract = $1;
            last;
        }
        close $fh;
        $abstract;
    },

    about_page_md => <<EOT,
This is an instance of the Coocook food planning software.
EOT

    # enable registration as self service, defaults to false
    enable_user_registration => 0,

    email_from_address => do {
        my $username = getpwuid($<);

        my $hostname = do {
            if ( eval "require Sys::Hostname::FQDN; 1" ) {
                Sys::Hostname::FQDN::fqdn();
            }
            elsif ( my $fqdn = `hostname --fqdn` ) {
                chomp $fqdn;
                $fqdn;
            }
            else { 'localhost' }
        };

        $username . '@' . $hostname;
    },

    email_signature => sub {
        my $c = shift;

        return $c->config->{name} . " " . $c->uri_for_action('/index');
    },

    project_deletion_confirmation => "I really want to loose my project",

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header                      => 1,    # Send X-Catalyst header
    use_hash_multivalue_in_request              => 1,    # safer return value for $c->req->params()

    request_class_traits => [
        'DisableParam',                                  # disable old, unsafe interface to request params
    ],

    'Model::DB' => {
        connect_info => {
            dsn => 'development',                        # referrs to dbic.yaml
        },
    },

    'Plugin::Authentication' => {
        default => {
            credential => {
                class          => 'Password',
                password_field => 'password_hash',
                password_type  => 'self_check',
            },
            store => {
                class      => 'DBIx::Class',
                user_model => 'DB::User',
            },
        }
    },

    session => {
        dbic_class      => 'DB::Session',
        expires         => 24 * 60 * 60, # 24h
        cookie_secure   => 2,            # deliver and accept only via HTTPS
        cookie_httponly => 1,            # make browser send cookie only via HTTP(S), not to JavaScript code
    },

    default_view => 'TT',

    'View::Email::Template' => {
        default => {
            view => 'TT',

            content_type => 'text/plain',
            charset      => 'utf-8',
            encoding     => 'quoted-printable',
        },
        sender => { mailer => $ENV{EMAIL_SENDER_TRANSPORT} || 'SMTP' },
    },

    'View::TT' => {
        INCLUDE_PATH => __PACKAGE__->path_to(qw< root templates >),
    },
);

# Start the application
__PACKAGE__->setup();

=encoding utf8

=head1 SYNOPSIS

    script/coocook_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Coocook::Controller::Root>, L<Catalyst>

=cut

1;
