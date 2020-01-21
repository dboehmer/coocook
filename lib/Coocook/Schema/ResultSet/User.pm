package Coocook::Schema::ResultSet::User;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::SortByName');

__PACKAGE__->meta->make_immutable;

sub sorted_by_columns { 'name_fc' }

sub site_owners {
    my $self = shift;

    return $self->search(
        {
            'roles_users.role' => 'site_owner',
        },
        {
            join => 'roles_users',
        }
    );
}

sub with_projects_count {
    my $self = shift;

    return $self->search(
        undef,
        {
            '+columns' => {
                projects_count => $self->correlate('owned_projects')->count_rs->as_query,
            },
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
