package Coocook;

# ABSTRACT: Web application for collecting recipes and making food plans
# VERSION

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use utf8;

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

## no critic (BuiltinFunctions::ProhibitStringyEval Subroutines::ProhibitSubroutinePrototypes)
# too bad Perl doesn't offer to check if a module is available
# other code (that passes perlcritic) for testing this is much more verbose
sub mod_installed ($) {
    my ($module) = @_;

    local $@;

    return eval("require $module; 1") ? $module : ();
}
## use critic

use Catalyst (
    qw<
      ConfigLoader
      +Coocook::Plugin::StrictTransportSecurity
      +Coocook::Plugin::UriForStatic
      Session
      Session::Store::DBIC
      Session::State::Cookie
      Authentication
      Static::Simple
      >,
    ( mod_installed 'Catalyst::Plugin::StackTrace' ? 'StackTrace' : () ),
);

extends 'Catalyst';

with 'Coocook::Helpers';

if ( $ENV{CATALYST_DEBUG} ) {    # Coocook->debug() doesn't work here, always returns false
    if ( mod_installed 'CatalystX::LeakChecker' ) {
        with 'CatalystX::LeakChecker';
    }

    # print e-mails on STDOUT in debugging mode
    $ENV{EMAIL_SENDER_TRANSPORT} //= 'Print';
}

# Configure the application.
#
# Note that settings in coocook.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

### DEFAULT/FACTORY SETTINGS ###
__PACKAGE__->config( name => 'Coocook' );    # referenced in next block

__PACKAGE__->config(

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

    about_page_title => "About",

    about_page_md => <<EOT,
This is an instance of the Coocook food planning software.

<!-- define 'about_page_md' in 'coocook_local' config file to replace this text -->
EOT

    # TODO move to local config of Coocook.org once 3rd party instances exist
    help_links => [
        {
            title => "Mailing list",
            url   => 'https://lists.coocook.org/mailman/listinfo/coocook',
        },
        {
            title => "Report issues",
            url   => 'https://github.com/dboehmer/coocook/issues',
        },
    ],

    # enable registration as self service, defaults to false
    enable_user_registration => 0,

    captcha => {
        form_min_time_secs => undef,    # minimum time between GET and POST /register
        form_max_time_secs => undef,    # maximum time between GET and POST /register
        use_hidden_input   => 0,        # lure bots into filling <input> hidden by CSS
    },

    registration_example_username => 'daniel_boehmer42',

    email_from_address => do {
        my $username =                  # see https://stackoverflow.com/a/3526587/498634
             ( $^O ne 'riscos' && $^O ne 'MSWin32' ? getpwuid($<) : undef )
          || ( $^O ne 'riscos' ? getlogin() : undef )
          || $ENV{USER}
          || 'coocook';

        my $hostname = do {
            if ( mod_installed 'Sys::Hostname::FQDN' ) {
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

    email_sender_name => __PACKAGE__->config->{name},

    email_signature => sub {
        my $c = shift;

        return $c->config->{name} . " " . $c->uri_for_action('/index');
    },

    # send e-mails to site_owners about new users registered
    notify_site_owners_about_registrations => 1,

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
                class         => 'DBIx::Class',
                user_model    => 'DB::User',
                role_relation => 'roles_users',
                role_field    => 'role',
            },
        }
    },

    'Plugin::StrictTransportSecurity' => {
        enabled => 1,
    },

    'Plugin::Session' => {
        dbic_class      => 'DB::Session',
        expires         => 24 * 60 * 60, # 24h
        cookie_secure   => 2,            # deliver and accept only via HTTPS
        cookie_httponly => 1,            # make browser send cookie only via HTTP(S), not to JavaScript code
    },

    default_view => 'HTML',

    'View::Email::TT' => {
        INCLUDE_PATH => __PACKAGE__->path_to(qw< root email_templates >),
    },

    'View::HTML' => {
        INCLUDE_PATH => [
            __PACKAGE__->path_to(qw< root custom_templates >),    # allow overriding with custom files
            __PACKAGE__->path_to(qw< root templates >),
        ],
    },
);

# Start the application
__PACKAGE__->setup();

=head1 SEE ALSO

L<Coocook::Controller::Root>, L<Catalyst>

=cut

1;
