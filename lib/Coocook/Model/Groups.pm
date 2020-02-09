package Coocook::Model::Groups;

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

    my $groups = $self->schema->resultset('Group');
    my $users  = $self->schema->resultset('User');

    return $self->schema->txn_do(
        sub {
            for my $rs ( $groups, $users ) {
                $rs->exists( { name_fc => $name_fc } )
                  and croak "Name is not available";
            }

            my $group = $groups->create( \%args );

            $group->add_to_groups_users( { role => 'owner', user => $args{owner} } );

            return $group;
        }
    );
}

sub find_by_name {
    my ( $self, $name ) = @_;

    return $self->schema->resultset('Group')->find( { name_fc => fc $name } );
}

1;
