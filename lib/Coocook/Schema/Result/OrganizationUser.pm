package Coocook::Schema::Result::OrganizationUser;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('organizations_users');

__PACKAGE__->add_columns(
    organization => { data_type => 'int' },
    user         => { data_type => 'int' },
    role         => { data_type => 'text' },
);

__PACKAGE__->set_primary_key(qw< organization user >);

__PACKAGE__->belongs_to( organization => 'Coocook::Schema::Result::Organization' );
__PACKAGE__->belongs_to( user         => 'Coocook::Schema::Result::User' );

__PACKAGE__->has_many(
    other_organizations_users => __PACKAGE__,
    sub {    # conditions above simple equality must use coderefs
             # https://metacpan.org/pod/DBIx::Class::Relationship::Base#Custom-join-conditions
        my $args = shift;

        return {
            "$args->{foreign_alias}.organization" => { -ident => "$args->{self_alias}.organization" },
            "$args->{foreign_alias}.user"         => { '!='   => { -ident => "$args->{self_alias}.user" } },
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
            $self->other_organizations_users->owners->update( { role => 'admin' } );

            # store new owner in project
            $self->organization->update( { owner => $self->get_column('user') } );

            # promote $self to owner
            $self->update( { role => 'owner' } );
        }
    );
}

1;
