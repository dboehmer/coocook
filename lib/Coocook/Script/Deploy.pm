package Coocook::Script::Deploy;

# ABSTRACT: script for database maintance based on App::DH

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

# TODO upgrade fails on Perl 5.26 because .pl file can't be found
# can be fixed by setting PERL_USE_UNSAFE_INC
# wrong assumption of '.' in @INC, probably in DBIx::Class::DeploymentHandler
#
# Can't locate share/ddl/SQLite/upgrade/4-5/002_url_names.pl
# in @INC (@INC contains: ...) at (eval 1153) line 4.
# at .../site_perl/5.26.0/Context/Preserve.pm line 43.
use lib '.';

extends 'App::DH';

has '+schema' => ( default => 'Coocook::Schema' );

sub _build_database { [qw< SQLite PostgreSQL >] }

__PACKAGE__->meta->make_immutable;

1;
