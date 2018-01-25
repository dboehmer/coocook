package Coocook::Schema::ResultSet::User;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->meta->make_immutable;

sub site_admins {
    my $self = shift;

    return $self->search(
        {
            'roles_users.role' => 'site_admin',
        },
        {
            join => 'roles_users',
        }
    );
}

sub with_valid_limited_token {
    my $self = shift;

    return $self->search(
        {
            $self->me('token_expires') => {    # AND
                '!=' => undef,
                '>'  => $self->format_datetime( DateTime->now ),
            }
        }
    );
}

sub with_valid_or_unlimited_token {
    my $self = shift;

    return $self->search(
        {
            $self->me('token_expires') => [    # OR
                '=' => undef,
                '>' => $self->format_datetime( DateTime->now )
            ]
        }
    );
}

1;
