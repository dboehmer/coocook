#!/usr/bin/env perl
use v5.30.0;
use strict;
use warnings;
use utf8;

use Term::ANSIColor;
use File::Basename;
use Cwd 'abs_path';
use Getopt::Long;
Getopt::Long::Configure("bundling");

# Directory where current script is located used to find other Coocook scripts
my $dir = abs_path( dirname(__FILE__) );

my $install = '';
my $upgrade = '';
my $debug   = '';
my $restart = '';

GetOptions(
    'install' => \$install,
    'upgrade' => \$upgrade,
    'debug'   => sub { $debug = '--debug' },
    'restart' => sub { $restart = '--restart' },
) or exit(1);

if ( defined $ARGV[0] ) {
    if ( $ARGV[0] eq 'deploy' ) {
        if ( $install and not $upgrade ) {
            deploy('install');

        }
        elsif ( $upgrade and not $install ) {
            deploy('upgrade');

        }
        elsif ( $install and $upgrade ) {
            error("'--install' and '--upgrade' may not be used together.");
            help();

        }
        else {
            say error("'$ARGV[1]' is not a valid flag for command 'deploy'.");
            say help();
            exit(1);
        }

    }
    elsif ( $ARGV[0] eq 'serve' ) {
        if ( defined $ARGV[1] ) {
            say error("'$ARGV[1]' is not a valid flag for command 'serve'");
            say help();
            exit(1);

        }
        else {
            server("$debug $restart");
        }

    }
    elsif ( $ARGV[0] eq 'help' ) {
        if ( defined $ARGV[1] ) {
            usage( $ARGV[1] );
            exit();

        }
        else {
            usage('commands');
            exit();

        }

    }
    else {
        say error("'$ARGV[0]' is not a valid command for $0.");
        say help();
        exit(1);
    }

}
else {
    say warning( "You provided no command to run. You probably meant to run "
          . colored( "'$0 serve --debug --reload'", 'blue' )
          . '?' );
    say help();
    exit(1);

}

sub deploy {
    my $flags = shift;

    exec "$dir/coocook_deploy.pl " . $flags;
}

sub server {
    my $flags = shift || '';

    exec "$dir/coocook_server.pl " . $flags;
}

sub error {
    my $msg = shift;

    return colored( 'ERROR:', 'red' ) . " $msg";
}

sub warning {
    my $msg = shift;

    return colored( 'WARNING:', 'yellow' ) . " $msg";
}

sub usage {
    my $command = shift;
    my %help    = (
        commands => qq{Usage:
    $0 [command] [flags]

    CLI Tool for managing Coocook instances.

    Commands:

	deploy            Manage the database of the Coocook instance
	serve             Run the local development server
	help              Display this and exit
	help [command]    Display help for specific command
	},

        deploy => qq{Usage:
    $0 deploy [flags]

    Manage the database of the Coocook instance.

    flags:

	-i --install    create new database
	-u --upgrade    upgrade existing database to fit new schema
	},

        serve => qq{Usage:
    $0 serve [flags]

    Run the local development server.

    flags:

	-d --debug      Enable debug output
	-r --restart    Enable live reload when files are changed
	},
        help => qq{Usage:
    $0 help [command]

    Display help for specific command.
	},
    );

    defined $help{$command} or say error("$command is not a valid command for $0.") and exit(1);

    say $help{$command};
}

sub help {
    return "You can use " . colored( "'$0 help'", 'blue' ) . " to get help on how to use this script.";
}
