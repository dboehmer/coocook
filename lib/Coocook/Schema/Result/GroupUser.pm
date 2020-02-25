package Coocook::Schema::Result::GroupUser;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('groups_users');

__PACKAGE__->add_columns(
    group => { data_type => 'int' },
    user  => { data_type => 'int' },
    role  => { data_type => 'text' },
);

__PACKAGE__->set_primary_key(qw< group user >);

__PACKAGE__->belongs_to( group => 'Coocook::Schema::Result::Group' );
__PACKAGE__->belongs_to( user  => 'Coocook::Schema::Result::User' );

__PACKAGE__->has_many(
    other_groups_users => __PACKAGE__,
    sub {    # conditions above simple equality must use coderefs
             # https://metacpan.org/pod/DBIx::Class::Relationship::Base#Custom-join-conditions
        my $args = shift;

        return {
            "$args->{foreign_alias}.group" => { -ident => "$args->{self_alias}.group" },
            "$args->{foreign_alias}.user"  => { '!='   => { -ident => "$args->{self_alias}.user" } },
        };
    }
);

__PACKAGE__->meta->make_immutable;

sub make_owner {
    my $self = shift;

    $self->role eq 'owner'
      and return warn "project_user.role already 'owner'";

    $self->role eq 'admin'
      or die "ownership can be transferred only to admins";

    $self->txn_do(
        sub {
            # demote other owner to admin
            $self->other_groups_users->owners->update( { role => 'admin' } );

            # store new owner in project
            $self->group->update( { owner => $self->get_column('user') } );

            # promote $self to owner
            $self->update( { role => 'owner' } );
        }
    );
}

1;
