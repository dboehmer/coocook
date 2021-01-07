package Coocook::Schema::ResultSet::User;

use feature 'fc';

use Data::Validate::Email 'is_email';
use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::SortByName');

__PACKAGE__->meta->make_immutable;

sub sorted_by_columns { 'name_fc' }

=head1 CHECK METHODS

=cut

sub email_valid_and_available {
    my ( $self, $email ) = @_;

    my $blacklist = $self->result_source->schema->resultset('BlacklistEmail');

    return (  is_email($email)
          and !$self->results_exist( { email_fc => fc $email } )
          and $blacklist->is_email_ok($email) );
}

sub name_available {
    my ( $self, $name ) = @_;

    my $name_fc = fc $name;

    my $blacklist     = $self->result_source->schema->resultset('BlacklistUsername');
    my $organizations = $self->result_source->schema->resultset('Organization');

    return (  !$self->results_exist( { name_fc => $name_fc } )
          and !$organizations->results_exist( { name_fc => $name_fc } )
          and $blacklist->is_username_ok($name) );
}

sub name_valid {
    my ( $self, $name ) = @_;

    defined($name)
      or return;

    return $name =~ m/ \A [0-9a-zA-Z_]+ \Z /x;
}

=head1 SUBSET METHODS

=cut

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

=head1 WITH EXTRA COLUMNS

=cut

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
