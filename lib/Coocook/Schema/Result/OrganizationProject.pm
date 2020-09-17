package Coocook::Schema::Result::OrganizationProject;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('organizations_projects');

__PACKAGE__->add_columns(
    organization_id => { data_type => 'integer' },
    project_id      => { data_type => 'integer' },
    role            => { data_type => 'text' },
);

__PACKAGE__->set_primary_key(qw< organization_id project_id >);

__PACKAGE__->belongs_to(
    organization => 'Coocook::Schema::Result::Organization',
    'organization_id'
);

__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project', 'project_id' );

__PACKAGE__->has_many(
    other_projects_organizations => __PACKAGE__,
    sub {    # conditions above simple equality must use coderefs
             # https://metacpan.org/pod/DBIx::Class::Relationship::Base#Custom-join-conditions
        my $args = shift;

        return {
            "$args->{foreign_alias}.project_id"      => { -ident => "$args->{self_alias}.project_id" },
            "$args->{foreign_alias}.organization_id" =>
              { '!=' => { -ident => "$args->{self_alias}.organization_id" } },
        };
    }
);

__PACKAGE__->meta->make_immutable;

1;
