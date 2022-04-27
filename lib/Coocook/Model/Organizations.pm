package Coocook::Model::Organizations;

use feature 'fc';    # Perl v5.16

use Carp;
use Moose;

extends 'Catalyst::Model';

has schema => (
    is  => 'rw',
    isa => 'Coocook::Schema',
);

__PACKAGE__->meta->make_immutable;

sub ACCEPT_CONTEXT {    # TODO this is called once per request. can we get $schema once for all?
    my ( $self, $c, @args ) = @_;

    $self->schema( $c->model('DB')->schema );

    return $self;
}

sub create {
    my ( $self, %args ) = @_;

    my $name_fc = fc $args{name};

    $args{display_name}   //= $args{name};
    $args{description_md} //= '';

    my $organizations = $self->schema->resultset('Organization');
    my $users         = $self->schema->resultset('User');

    return $self->schema->txn_do(
        sub {
            for my $rs ( $organizations, $users ) {
                $rs->results_exist( { name_fc => $name_fc } )
                  and croak "Name is not available";
            }

            my $organization = $organizations->create( \%args );

            $organization->add_to_organizations_users( { role => 'owner', user_id => $args{owner_id} } );

            return $organization;
        }
    );
}

sub find_by_name {
    my ( $self, $name ) = @_;

    return $self->schema->resultset('Organization')->find( { name_fc => fc $name } );
}

=head2 name_available("name")

Returns a boolean value indicating whether the given name
is not used for users/organizations and not blacklisted.

=cut

sub name_available {
    my ( $self, $name ) = @_;

    my $name_fc = fc($name);

    return (  !$self->schema->resultset('Organization')->results_exist( { name_fc => $name_fc } )
          and !$self->schema->resultset('User')->results_exist( { name_fc => $name_fc } )
          and $self->schema->resultset('BlacklistUsername')->is_username_ok($name) );
}

sub name_valid {
    my ( $self, $name ) = @_;

    defined($name)
      or return;

    return $name =~ m/ \A [0-9a-zA-Z_]+ \z /x;
}

1;
