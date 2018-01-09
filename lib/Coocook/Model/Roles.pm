package Coocook::Model::Roles;

# ABSTRACT: static definition which roles grant which permissions

use strict;
use warnings;

my %permissions2roles = (
    make_project_private => 'private_projects',    # perltidy
);

# transform scalars/arrays into hashrefs
# role 'admin' has every permissions
for ( values %permissions2roles ) {
    $_ = { map { $_ => 1 } ( 'admin', ref eq 'ARRAY' ? @$_ : $_ ) };
}

my %roles2permissions;

while ( my ( $permission => $roles ) = each %permissions2roles ) {
    for my $role ( keys %$roles ) {
        $roles2permissions{$role}{$permission} = 1;
    }
}

#Test::Most::explain {
#    permissions2roles => \%permissions2roles,
#    roles2permissions => \%roles2permissions
#};

=head2 METHODS

=cut

my $singleton;

sub new {
    return $singleton ||= bless {}, __PACKAGE__;
}

sub permission_exists {
    my ( $self, $permission ) = @_;

    return exists $permissions2roles{$permission};
}

sub role_exists {
    my ( $self, $role ) = @_;

    return exists $roles2permissions{$role};
}

sub roles_with_permission {
    my ( $self, $permission ) = @_;

    my @roles = keys %{ $permissions2roles{$permission} };

    return wantarray ? @roles : \@roles;
}

sub role_has_permission {
    my ( $self, $role => $permission ) = @_;

    return $roles2permissions{$role}{$permission};
}

1;
