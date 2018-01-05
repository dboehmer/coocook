package Coocook::Schema::Result::User;

our $SALT_BYTES         = 16;
our $ARGON2_T_COST      = 3;
our $ARGON2_M_FACTOR    = '32M';
our $ARGON2_PARALLELISM = 1;
our $ARGON2_TAG_SIZE    = 16;

use Crypt::Argon2 qw< argon2i_pass argon2i_verify >;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use Net::SSLeay;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('users');

__PACKAGE__->add_columns(
    id             => { data_type => 'int',      is_auto_increment => 1 },
    name           => { data_type => 'text' },
    password_hash  => { data_type => 'text' },
    display_name   => { data_type => 'text' },
    role           => { data_type => 'text' },
    email          => { data_type => 'text' },
    email_verified => { data_type => 'datetime', is_nullable       => 1 },
    token          => { data_type => 'text',     is_nullable       => 1 },
    token_expires  => { data_type => 'datetime', is_nullable       => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( ['name'], ['token'] );

__PACKAGE__->has_many( owned_projects => 'Coocook::Schema::Result::Project', 'owner' );

__PACKAGE__->has_many( projects_users => 'Coocook::Schema::Result::ProjectUser' );
__PACKAGE__->many_to_many( projects => projects_users => 'project' );

# support virtual 'password' column
around [ 'set_column', 'store_column' ] => sub {
    my ( $orig, $self, $column => $value ) = @_;

    if ( $column eq 'password' ) {
        Net::SSLeay::RAND_bytes( my $salt, $SALT_BYTES )
          or die "Net::SSLeay couldn't deliver $SALT_BYTES random bytes";

        my $password_hash =
          argon2i_pass( $value, $salt, $ARGON2_T_COST, $ARGON2_M_FACTOR, $ARGON2_PARALLELISM,
            $ARGON2_TAG_SIZE );

        ( $column => $value ) = ( password_hash => $password_hash );
    }

    return $self->$orig( $column => $value );
};

__PACKAGE__->meta->make_immutable;

sub check_password {    # method name defined by Catalyst::Authentication::Credential::Password
    my ( $self, $password ) = @_;

    return argon2i_verify( $self->password_hash, $password );
}

1;
