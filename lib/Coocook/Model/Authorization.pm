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
        needs_input => ['user'],
        rule        => sub { !!shift->{user} },
        capabilities =>
          [qw< dashboard logout create_project view_user_settings change_display_name change_password >],
    },
    {
        needs_input => ['project'],    # optional: user
        rule        => sub {
            my ( $project, $user ) = @{ +shift }{ 'project', 'user' };
            return (
                $project->is_public
                  or (
                    $user
                    and (  $user->has_role('site_admin')
                        or $user->has_any_project_role( $project, qw< viewer editor admin owner > ) )
                  )
            );
        },
        capabilities => [qw< view_project import_from_project >],
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
        capabilities => [qw< edit_project import_into_project >],
    },
    {
        needs_input => [ 'project', 'user' ],
        rule        => sub {
            my ( $project, $user ) = @{ +shift }{ 'project', 'user' };
            return (
                     $user->has_role('site_admin')
                  or $user->has_any_project_role( $project, qw< admin owner > )
            );
        },
        capabilities => 'view_project_permissions',
    },
    {
        needs_input => [ 'project', 'user' ],
        rule        => sub {
            my ( $project, $user ) = @{ +shift }{ 'project', 'user' };
            return ( $user->has_role('site_admin') or $user->has_project_role( $project, 'owner' ) );
        },
        capabilities =>
          [qw< view_project_settings create_project_permission rename_project delete_project >],
    },
    {
        needs_input => [ 'project', 'permission', 'user' ],
        rule        => sub {
            my ( $project, $permission, $user ) = @{ +shift }{ 'project', 'permission', 'user' };
            return (  $permission->user->id != $user->id
                  and $permission->role ne 'owner'
                  and ( $user->has_role('site_admin') or $user->has_project_role( $project, 'owner' ) ) );
        },
        capabilities => [qw< edit_project_permission revoke_project_permission >],
    },
    {
        needs_input  => 'user',
        rule         => sub { shift->{user}->has_any_role( 'site_admin', 'private_projects' ) },
        capabilities => 'create_private_project',
    },
    {
        needs_input => [ 'project', 'user' ],
        rule        => sub {
            my ( $project, $user ) = @{ +shift }{ 'project', 'user' };
            return (
                $user->has_role('site_admin')
                  or ( $user->has_role('private_projects') and $user->has_project_role( $project, 'owner' ) )
            );
        },
        capabilities => [qw< make_project_private edit_project_visibility >],
    },
    {
        needs_input => [ 'user', 'project', 'permission' ],
        rule        => sub {
            my ( $project, $user, $permission ) = @{ +shift }{ 'project', 'user', 'permission' };

            # can be transferred only to admin
            $permission->role eq 'admin' or return;

            # allow transfer from current owner
            return 1 if $user->has_project_role( $project, 'owner' );

            # allow transfer from site admin
            return 1 if $user->has_role('site_admin');

            return;
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

sub capability_exists {
    my ( $self, $capability ) = @_;

    return exists $capabilities{$capability};
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

sub project_roles { qw< viewer editor admin owner > }

1;
