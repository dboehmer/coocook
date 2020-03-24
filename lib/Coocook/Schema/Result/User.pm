package Coocook::Schema::Result::User;

use Coocook::Model::Token;
use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use feature 'fc';    # Perl v5.16

extends 'Coocook::Schema::Result';

__PACKAGE__->table('users');

__PACKAGE__->add_columns(
    id             => { data_type => 'int', is_auto_increment => 1 },
    name           => { data_type => 'text' },
    name_fc        => { data_type => 'text' },                          # fold cased
    password_hash  => { data_type => 'text' },
    display_name   => { data_type => 'text' },
    admin_comment  => { data_type => 'text', default_value => '' },
    email_fc       => { data_type => 'text' },
    email_verified => { data_type => 'datetime', is_nullable => 1 },
    token_hash     => { data_type => 'text', is_nullable => 1 },
    token_expires  => { data_type => 'datetime', is_nullable => 1 },
    created => { data_type => 'datetime', default_value => \'CURRENT_TIMESTAMP', set_on_create => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints(
    ['name'], ['name_fc'], ['email_fc'],
    ['password_hash'],    # passwords might be equal but salted hash MUST be unique
    ['token_hash'],
);

__PACKAGE__->has_many( roles_users => 'Coocook::Schema::Result::RoleUser', 'user_id' );

__PACKAGE__->has_many(
    owned_projects => 'Coocook::Schema::Result::Project',
    'owner_id',
    {
        cascade_delete => 0,    # users who own projects may not be deleted
    }
);

__PACKAGE__->has_many(
    organizations_users => 'Coocook::Schema::Result::OrganizationUser',
    'user_id'
);
__PACKAGE__->many_to_many( organizations => organizations_users => 'organization' );

__PACKAGE__->has_many( projects_users => 'Coocook::Schema::Result::ProjectUser', 'user_id' );
__PACKAGE__->many_to_many( projects => projects_users => 'project' );

__PACKAGE__->has_many( terms_users => 'Coocook::Schema::Result::TermsUser', 'user_id' );
__PACKAGE__->many_to_many( terms => terms_users => 'terms' );

around [ 'set_column', 'store_column' ] => sub {
    my ( $orig, $self, $column => $value ) = @_;

    if ( $column eq 'name' ) {    # automatically set 'name_fc' from 'name'
        $self->$orig( name_fc => fc($value) );
    }
    elsif ( $column eq 'password' ) {    # support virtual 'password' column
        my $password = Coocook::Model::Token->from_string($value);

        ( $column => $value ) = ( password_hash => $password->to_salted_hash );
    }

    return $self->$orig( $column => $value );
};

__PACKAGE__->meta->make_immutable;

sub blacklist {
    my $self = shift;

    $self->txn_do(
        sub {
            $self->result_source->schema->resultset('BlacklistEmail')->add_email( $self->email_fc, @_ );
            $self->result_source->schema->resultset('BlacklistUsername')->add_username( $self->name, @_ );
        },
        @_
    );
}

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

sub has_any_role {
    my $self = shift;

    my $roles = ( @_ == 1 and ref $_[0] eq 'ARRAY' ) ? $_[0] : \@_;

    return $self->roles_users->results_exist( { role => { -in => $roles } } );
}

sub has_any_project_role {
    my $self    = shift;
    my $project = shift;

    my $roles = ( @_ == 1 and ref $_[0] eq 'ARRAY' ) ? $_[0] : \@_;

    return $self->projects_users->results_exist(
        { project_id => $project->id, role => { -in => $roles } } );
}

sub has_any_organization_role {
    my $self         = shift;
    my $organization = shift;

    my $roles = ( @_ == 1 and ref $_[0] eq 'ARRAY' ) ? $_[0] : \@_;

    return $self->organizations_users->results_exist(
        { organization_id => $organization->id, role => { -in => $roles } } );
}

sub roles {
    my $self = shift;

    return $self->roles_users->get_column('role')->all;
}

sub status_code        { ( shift->status )[0] }
sub status_description { ( shift->status )[1] }

sub status {
    my $self = shift;

    if ( $self->email_verified ) {
        if ( my $token_expires = $self->token_expires ) {
            if ( DateTime->now <= $token_expires ) {
                return password_recovery => sprintf "requested password recovery link (valid until %s)",
                  $token_expires;
            }
        }

        return ok => "ok";
    }

    return unverified => "e-mail address not yet verified with verification link";
}

1;
