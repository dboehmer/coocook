package Coocook::Model::Authorization;

# ABSTRACT: validation of action requests by pre-defined roles

use strict;
use warnings;

use Carp;

# TODO invent some syntax sugar to avoid defining variables twice
#      and extract them from %$_ by hand
#
# - unfortunately Perl::Tidy doesn't work with Method::Signatures
# - method attributes like sub foo : Foo Bar {} work but need string parsing
# - how to define lexical variables like $project before calling the anonymous sub?
my @rules = (
    {
        needs_input  => [],
        rule         => sub { 1 },                      # currently no actual check required
        capabilities => [qw< view_group view_user >],
    },
    {
        needs_input  => ['user'],
        rule         => sub { !!$_->{user} },           # simply: is anyone logged in?
        capabilities => [
            qw<
              view_dashboard create_project
              view_account_settings change_display_name change_password
              view_user_groups create_group
              view_user_projects
              logout
              >
        ],
    },
    {
        needs_input => [ 'group', 'user' ],
        rule        => sub {
            my ( $group, $user ) = @$_{ 'group', 'user' };
            return (
                     $user->has_any_role('site_owner')
                  or $user->search_related( groups_users => { group => $group->id } )->exists
            );
        },
        capabilities => [qw< view_group_members >],
    },
    {
        needs_input => [ 'group', 'user' ],
        rule        => sub {
            my ( $group, $user ) = @$_{ 'group', 'user' };
            return if $group->get_column('owner') == $user->id;               # owner must not leave
            return $user->groups_users->exists( { group => $group->id } );    # user is group member?
        },
        capabilities => [qw< leave_group >],
    },
    {
        needs_input => [ 'group', 'user' ],
        rule        => sub {
            my ( $group, $user ) = @$_{ 'group', 'user' };
            return (
                     $user->has_any_role('site_owner')
                  or $user->has_any_group_role( $group, 'owner', 'admin' )
            );
        },
        capabilities => [qw< edit_group >],
    },
    {
        needs_input => [ 'user', 'group', 'user_object', 'role' ],
        rule        => sub {
            my ( $user, $group, $user_object, $role ) = @$_{ 'user', 'group', 'user_object', 'role' };

            return if $role eq 'owner';
            return unless grep { $role eq $_ } group_roles();

            return if $group->groups_users->exists( { user => $user_object->id } );    # is already group member

            return ( $user->has_any_role('site_owner') or $user->has_any_group_role( $group, 'owner' ) );
        },
        capabilities => [qw< add_user_to_group >],
    },
    {
        needs_input => [ 'user', 'group', 'membership' ],
        rule        => sub {
            my ( $capability, $user, $group, $membership ) = @$_{ 'capability', 'user', 'group', 'membership' };

            return if $membership->role eq 'owner';
            return if $membership->user->id == $user->id and not $user->has_any_role('site_owner');

            return (
                $user->has_any_role('site_owner')
                  or (
                    $user->has_any_group_role(
                        $group,

                        # removal of viewers is permitted for admins, too,
                        # otherwise only owners
                        $capability eq 'remove_user_from_group' && $membership->role eq 'viewer'
                        ? ( 'owner', 'admin' )
                        : ('owner')
                    )
                  )
            );
        },
        capabilities => [qw< edit_group_membership remove_user_from_group >],
    },
    {
        needs_input => [ 'user', 'group', 'membership' ],
        rule        => sub {
            my ( $group, $user, $membership ) = @$_{ 'group', 'user', 'membership' };
            return (
                $membership->role eq 'admin'    # can be transferred only to admin
                  and (
                    $user->has_any_group_role( $group, 'owner' )    # allow transfer by current owner
                    or $user->has_any_role('site_owner')            # allow transfer by site admin
                  )
            );
        },
        capabilities => 'transfer_group_ownership',
    },
    {
        needs_input => [ 'user', 'group' ],
        rule        => sub {
            my ( $group, $user ) = @$_{ 'group', 'user' };
            return ( $user->has_any_group_role( $group, 'owner' ) or $user->has_any_role('site_owner') );
        },
        capabilities => 'delete_group',
    },
    {
        needs_input => ['project'],    # optional: user
        rule        => sub {
            my ( $project, $user ) = @$_{ 'project', 'user' };
            return (
                $project->is_public
                  or (
                    $user
                    and (  $user->has_any_role('site_owner')
                        or $user->has_any_project_role( $project, qw< viewer editor admin owner > ) )
                  )
            );
        },
        capabilities => [qw< view_project >],
    },
    {
        needs_input => [
            'source_project', 'user'  # export_from_project requires $user to present list of their own projects
        ],
        rule => sub {
            my ( $source_project, $user ) = @$_{ 'source_project', 'user' };
            return (
                     $source_project->is_public
                  or $user->has_any_role('site_owner')
                  or $user->has_any_project_role( $source_project, qw< viewer editor admin owner > )
            );
        },
        capabilities => [qw< export_from_project >],
    },
    {
        needs_input => [ 'project', 'user' ],
        rule        => sub {
            my ( $project, $user ) = @$_{ 'project', 'user' };
            $project->archived and return;
            return (
                     $user->has_any_role('site_owner')
                  or $user->has_any_project_role( $project, qw< editor admin owner > )
            );
        },
        capabilities => [qw< edit_project import_into_project >],
    },
    {
        needs_input => [ 'project', 'user' ],
        rule        => sub {
            my ( $project, $user, $capability ) = @$_{ 'project', 'user', 'capability' };

            return if $capability eq 'archive_project'   and $project->archived;
            return if $capability eq 'unarchive_project' and not $project->archived;

            return ( $user->has_any_role('site_owner') or $user->has_any_project_role( $project, 'owner' ) );
        },
        capabilities => [
            qw<
              view_project_settings
              view_project_permissions
              update_project rename_project delete_project
              archive_project unarchive_project
              >
        ],
    },
    {
        needs_input => [ 'project', 'user', 'role' ],
        rule        => sub {
            my ( $capability, $project, $user, $role ) = @$_{ 'capability', 'project', 'user', 'role' };

            return if $role eq 'owner';
            return unless grep { $role eq $_ } project_roles();

            my $permissions =
                $capability eq 'add_group_permission' ? $_->{group}->groups_projects
              : $capability eq 'add_user_permission'  ? $_->{user_object}->projects_users
              :                                         die "code broken";

            return if $permissions->exists( { project => $project->id } );    # already has permission

            return ( $user->has_any_role('site_owner') or $user->has_any_project_role( $project, 'owner' ) );
        },
        capabilities => [qw< add_group_permission add_user_permission >],
    },
    {
        needs_input => [ 'project', 'permission', 'user' ],
        rule        => sub {
            my ( $capability, $project, $permission, $user ) = @$_{qw<capability project permission user>};

            if (   $capability eq 'edit_project_permission'
                or $capability eq 'edit_group_permission'
                or $capability eq 'edit_user_permission' )
            {    # for editing permissions: new role must be valid
                my $role = $_->{role} || croak "missing input key 'role'";
                return if $role eq 'owner';
                return unless grep { $role eq $_ } project_roles();
            }

            # owner must never be removed/degraded (transfer ownership first!)
            return if $permission->role eq 'owner';

            # site owners have full control
            return 1 if $user->has_any_role('site_owner');

            # for user permissions: users must not edit their own permission
            return
              if $permission->result_source->source_name eq 'ProjectUser'
              and $permission->user->id == $user->id;

            # user is project owner?
            return $user->has_any_project_role( $project, 'owner' );
        },
        capabilities => [
            'edit_project_permission', 'revoke_project_permission',    # generic aliases
            qw<
              edit_group_permission revoke_group_permission
              edit_user_permission  revoke_user_permission
              >
        ],
    },
    {
        needs_input  => 'user',
        rule         => sub { $_->{user}->has_any_role( 'site_owner', 'private_projects' ) },
        capabilities => 'create_private_project',
    },
    {
        needs_input => [ 'project', 'user' ],
        rule        => sub {
            my ( $project, $user ) = @$_{ 'project', 'user' };
            return (
                $user->has_any_role('site_owner')
                  or
                  ( $user->has_any_role('private_projects') and $user->has_any_project_role( $project, 'owner' ) )
            );
        },
        capabilities => [qw< make_project_private edit_project_visibility >],
    },
    {
        needs_input => [ 'user', 'project', 'permission' ],
        rule        => sub {
            my ( $project, $user, $permission ) = @$_{ 'project', 'user', 'permission' };

            # can be transferred only to admin
            $permission->role eq 'admin' or return;

            # allow transfer by current owner
            return 1 if $user->has_any_project_role( $project, 'owner' );

            # allow transfer by site admin
            return 1 if $user->has_any_role('site_owner');

            return;
        },
        capabilities => 'transfer_project_ownership',
    },
    {
        needs_input => ['recipe'],
        rule        => sub {
            my ( $recipe, $user ) = @$_{ 'recipe', 'user' };

            return 1 if $recipe->project->is_public;

            return 1
              if $user and $user->has_any_project_role( $recipe->project, qw< viewer editor admin owner > );

            return 1 if $user and $user->has_any_role('site_owner');

            return;
        },
        capabilities => ['view_recipe'],
    },
    {
        needs_input => [ 'user', 'project', 'recipe' ],
        rule        => sub {
            my ( $user, $project, $recipe ) = @$_{ 'user', 'project', 'recipe' };

            # recipe must not be in target project
            $recipe->get_column('project') != $project->id
              or return;

            return 1 if $user->has_any_role('site_owner');

            return 1 if $user->has_any_project_role( $project, qw< viewer editor admin owner > );

            return;
        },
        capabilities => 'import_recipe',
    },
    {
        needs_input  => ['user'],
        rule         => sub { $_->{user}->has_any_role('site_owner') },
        capabilities => [qw< admin_view manage_faqs manage_terms manage_users view_all_recipes >],
    },
    {
        needs_input => [ 'user', 'user_object' ],
        rule        => sub {
            my ( $user, $user_object ) = @$_{ 'user', 'user_object' };
            $user->has_any_role('site_owner') or return;
            $user->id != $user_object->id     or return;
            return 1;
        },
        capabilities => ['toggle_site_owner'],
    },
    {
        needs_input => [ 'user', 'user_object' ],
        rule        => sub {
            my ( $user, $user_object ) = @$_{ 'user', 'user_object' };
            $user->has_any_role('site_owner')         or return;
            $user_object->status_code eq 'unverified' or return;
            return 1;
        },
        capabilities => ['discard_user'],
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
        $capabilities{$capability}
          and die "capabilities can be granted by only 1 rule: '$capability'";

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

sub capability_needs_input {
    my ( $self, $capability ) = @_;

    my $rule = $capabilities{$capability}
      or croak "no such capability '$capability'";

    return @{ $rule->{needs_input} };
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

    local $input->{capability} = $capability;

    local $_ = $input;

    return $rule->{rule}->() ? 1 : ();
}

sub group_roles { qw< member admin owner > }

sub project_roles { qw< viewer editor admin owner > }

1;
