package Coocook::Schema::Result::OrganizationProject;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('organizations_projects');

__PACKAGE__->add_columns(
    organization => { data_type => 'int' },
    project      => { data_type => 'int' },
    role         => { data_type => 'text' },
);

__PACKAGE__->set_primary_key(qw< organization project >);

__PACKAGE__->belongs_to( organization => 'Coocook::Schema::Result::Organization' );
__PACKAGE__->belongs_to( project      => 'Coocook::Schema::Result::Project' );

__PACKAGE__->has_many(
    other_projects_organizations => __PACKAGE__,
    sub {    # conditions above simple equality must use coderefs
             # https://metacpan.org/pod/DBIx::Class::Relationship::Base#Custom-join-conditions
        my $args = shift;

        return {
            "$args->{foreign_alias}.project" => { -ident => "$args->{self_alias}.project" },
            "$args->{foreign_alias}.organization" =>
              { '!=' => { -ident => "$args->{self_alias}.organization" } },
        };
    }
);

__PACKAGE__->meta->make_immutable;

1;
