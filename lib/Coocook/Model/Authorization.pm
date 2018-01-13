package Coocook::Model::Authorization;

# ABSTRACT: validation of action requests by pre-defined roles

use strict;
use warnings;

use Carp;

# TODO invent some syntax sugar to avoid defining variables twice
#      and extract them from %{ $_[0] } by hand
#
# - unfortunately Perl::Tidy doesn't work with Method::Signatures
# - method attributes like sub foo : Foo Bar {} work but need string parsing
# - how to define lexical variables like $project before calling the anonymous sub?
my @rules = (
    {
        needs_input => ['project'],    # optional: user
        rule        => sub {
            my ( $project, $user ) = @{ +shift }{ 'project', 'user' };
            return (
                $project->is_public
                  or ( $user and $user->has_any_project_role( $project, qw< viewer editor admin owner > ) )
            );
        },
        capabilities => 'view_project',
    },
    {
        needs_input => [ 'project', 'user' ],
        rule        => sub {
            my ( $project, $user ) = @{ +shift }{ 'project', 'user' };
            return (
                     $user->has_role('site_admin')
                  or $user->has_any_project_role( $project, qw< editor admin owner > )
            );
        },
        capabilities => 'edit_project',
    },
    {
        needs_input => [ 'project', 'user' ],
        rule        => sub {
            my ( $project, $user ) = @{ +shift }{ 'project', 'user' };
            return ( $user->has_role('site_admin') or $user->has_project_role( $project, 'owner' ) );
        },
        capabilities => [qw< view_project_settings rename_project delete_project >],
    },
    {
        needs_input => 'user',
        rule        => sub { shift->{user}->has_any_role( 'site_admin', 'private_projects' ) },
        capabilities => [ 'create_private_project', 'make_project_private' ],
    },
    {
        needs_input => [ 'user', 'project', 'new_owner' ],
        rule        => sub {
            my $input = shift;
            return (
                (
                         $input->{user}->has_role('site_admin')
                      or $input->{user}->has_project_role( $input->{project}, 'owner' )
                )
                  and $input->{new_owner}->has_project_role( $input->{project}, 'admin' )
            );
        },
        capabilities => 'transfer_project_ownership',
    },
);

my %capabilities;

for my $rule (@rules) {

    for my $key (qw< needs_input capabilities >) {
        for ( $rule->{$key} ) {    # transform scalars into arrayrefs
            ref($_) eq 'ARRAY'
              or $_ = [$_];
        }
    }

    for my $capability ( @{ $rule->{capabilities} } ) {
        $capabilities{$capability} and die "capability can be granted by only 1 rule";

        $capabilities{$capability} = $rule;
    }
}

#Test::Most::explain \%capabilities;

=head2 METHODS

=cut

my $singleton;

sub new {
    return $singleton ||= bless {}, __PACKAGE__;
}

sub has_capability {
    my ( $self, $capability, $input ) = @_;

    my $rule = $capabilities{$capability}
      or croak "no such capability '$capability'";

    ref $input eq 'HASH'
      or croak "input must be hashref";

    # invalid call of caller doesn't pass hash keys
    for my $key ( @{ $rule->{needs_input} }, 'user' ) {   # key 'user' is always required, even if undef
        exists $input->{$key}
          or croak "missing input key '$key'";
    }

    # unauthorized request if required input isn't present
    for my $key ( @{ $rule->{needs_input} } ) {
        $input->{$key}
          or return;
    }

    return $rule->{rule}->($input);
}

1;
