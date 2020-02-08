package Coocook::Schema::Result::GroupProject;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('groups_projects');

__PACKAGE__->add_columns(
    group   => { data_type => 'int' },
    project => { data_type => 'int' },
    role    => { data_type => 'text' },
);

__PACKAGE__->set_primary_key(qw< group project >);

__PACKAGE__->belongs_to( group   => 'Coocook::Schema::Result::Group' );
__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project' );

__PACKAGE__->has_many(
    other_projects_groups => __PACKAGE__,
    sub {    # conditions above simple equality must use coderefs
             # https://metacpan.org/pod/DBIx::Class::Relationship::Base#Custom-join-conditions
        my $args = shift;

        return {
            "$args->{foreign_alias}.group"   => { '!='   => { -ident => "$args->{self_alias}.group" } },
            "$args->{foreign_alias}.project" => { -ident => "$args->{self_alias}.project" },
        };
    }
);

__PACKAGE__->meta->make_immutable;

1;
