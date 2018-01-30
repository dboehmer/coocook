package Coocook::Schema::Result::User;

use Coocook::Model::Token;
use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use feature 'fc';    # Perl v5.16

extends 'Coocook::Schema::Result';

__PACKAGE__->table('users');

__PACKAGE__->add_columns(
    id   => { data_type => 'int', is_auto_increment => 1 },
    name => { data_type => 'text' },
    name_fc        => { data_type => 'text' },                         # fold cased
    password_hash  => { data_type => 'text' },
    display_name   => { data_type => 'text' },
    email          => { data_type => 'text' },
    email_verified => { data_type => 'datetime', is_nullable => 1 },
    token_hash     => { data_type => 'text', is_nullable => 1 },
    token_expires  => { data_type => 'datetime', is_nullable => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( ['name'], ['name_fc'], ['email'], ['token_hash'] );

__PACKAGE__->has_many( roles_users => 'Coocook::Schema::Result::RoleUser' );

__PACKAGE__->has_many( owned_projects => 'Coocook::Schema::Result::Project', 'owner' );

__PACKAGE__->has_many( projects_users => 'Coocook::Schema::Result::ProjectUser' );
__PACKAGE__->many_to_many( projects => projects_users => 'project' );

# support virtual 'password' column
around [ 'set_column', 'store_column' ] => sub {
    my ( $orig, $self, $column => $value ) = @_;

    if ( $column eq 'name' ) {
        $self->$orig( name_fc => fc($value) );
    }
    elsif ( $column eq 'password' ) {
        my $password = Coocook::Model::Token->from_string($value);

        ( $column => $value ) = ( password_hash => $password->to_salted_hash );
    }

    return $self->$orig( $column => $value );
};

__PACKAGE__->meta->make_immutable;

sub check_password {    # method name defined by Catalyst::Authentication::Credential::Password
    my ( $self, $password ) = @_;

    return Coocook::Model::Token->from_string($password)->verify_salted_hash( $self->password_hash );
}

sub check_base64_token {
    my ( $self, $token ) = @_;

    if ( my $expires = $self->token_expires ) {
        $expires > DateTime->now
          or return;
    }

    return Coocook::Model::Token->from_base64($token)->verify_salted_hash( $self->token_hash );
}

sub add_roles {
    my ( $self, @roles ) = @_;

    if ( @roles == 1 and ref $roles[0] eq 'ARRAY' ) {
        @roles = @{ $roles[0] };
    }

    for my $role (@roles) {
        $self->create_related( roles_users => { role => $role } );
    }
}

sub has_role {
    my ( $self, $role ) = @_;

    return $self->roles_users->exists( { role => $role } );
}

sub has_any_role {
    my $self = shift;

    my $roles = ( @_ == 1 and ref $_[0] eq 'ARRAY' ) ? $_[0] : \@_;

    return $self->roles_users->exists( { role => { -in => $roles } } );
}

sub has_project_role {
    my ( $self, $project, $role ) = @_;

    return $self->projects_users->exists( { project => $project->id, role => $role } );
}

sub has_any_project_role {
    my $self    = shift;
    my $project = shift;

    my $roles = ( @_ == 1 and ref $_[0] eq 'ARRAY' ) ? $_[0] : \@_;

    return $self->projects_users->exists( { project => $project->id, role => { -in => $roles } } );
}

sub roles {
    my $self = shift;

    return $self->roles_users->get_column('role')->all;
}

1;
