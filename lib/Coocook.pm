package Coocook;

# ABSTRACT: Web application for collecting recipes and making food plans
# VERSION

use Moose;
use namespace::autoclean;

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
  StackTrace
  Static::Simple
  /;

extends 'Catalyst';

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

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header                      => 1,   # Send X-Catalyst header
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
