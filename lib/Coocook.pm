package Coocook;

# ABSTRACT: Web application for collecting recipes and making food plans
# VERSION

use HTML::Entities ();
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

use Catalyst qw/
  ConfigLoader
  Session
  Session::Store::FastMmap
  Session::State::Cookie
  Authentication
  StackTrace
  Static::Simple
  /;

extends 'Catalyst';

$ENV{CATALYST_DEBUG}
  and with 'CatalystX::LeakChecker';    # TODO add as dependency or check if module is installed?

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

    homepage_text_md => do {    # Markdown text for homepage, default: abstract of Coocook.pm
        open my $fh, __FILE__;    # read abstract from this file
        my $abstract;
        while (<$fh>) {
            /^# ?ABSTRACT: (.+)$/ or next;
            $abstract = $1;
            last;
        }
        close $fh;
        $abstract;
    },

    project_deletion_confirmation => "I really want to loose my project",

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header                      => 1,    # Send X-Catalyst header

    'Model::DB' => {
        connect_info => {
            dsn => 'development',                        # referrs to dbic.yaml
        },
    },

    'Plugin::Authentication' => {
        default => {
            credential => {
                class          => 'Password',
                password_field => 'password',
                password_type  => 'clear',
            },
            store => {
                class => 'Minimal',
                users => {
                    coocook => { password => "coocook" }
                },
            },
        }
    },

    'View::TT' => {
        INCLUDE_PATH => __PACKAGE__->path_to(qw< root templates >),
    },
);

sub encode_entities {
    my ( $self, $text ) = @_;
    return HTML::Entities::encode_entities($text);
}

sub escape_title {
    my ( $self, $title, $text ) = @_;

    $self->stash(
        title      => "$title \"$text\"",
        html_title => "$title <em>" . $self->encode_entities($text) . "</em>",
    );
}

# custom helper
# TODO maybe move to designated helper module?
sub project_uri {
    my $c      = shift;
    my $action = shift;

    my $project = $c->stash->{project} || die;

    # if last argument is hashref that's the \%query_values argument
    my @query = ref $_[-1] eq 'HASH' ? pop @_ : ();

    return $c->uri_for_action( $action, [ $project->url_name, @_ ], @query );
}

# another helper
sub project {
    my $c = shift;

    $c->stash->{project};
}

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
