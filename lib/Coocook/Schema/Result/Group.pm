package Coocook::Schema::Result::Group;

use Coocook::Model::Token;
use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use feature 'fc';    # Perl v5.16

extends 'Coocook::Schema::Result';

__PACKAGE__->table('groups');

__PACKAGE__->add_columns(
    id             => { data_type => 'int', is_auto_increment => 1 },
    name           => { data_type => 'text' },
    name_fc        => { data_type => 'text' },                          # fold cased
    owner          => { data_type => 'int' },
    description_md => { data_type => 'text' },
    display_name   => { data_type => 'text' },
    admin_comment  => { data_type => 'text', default_value => '' },
    created => { data_type => 'datetime', default_value => \'CURRENT_TIMESTAMP', set_on_create => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( ['name'], ['name_fc'] );

__PACKAGE__->belongs_to( owner => 'Coocook::Schema::Result::User' );

__PACKAGE__->has_many( groups_projects => 'Coocook::Schema::Result::GroupProject' );
__PACKAGE__->many_to_many( projects => groups_projects => 'project' );

__PACKAGE__->has_many( groups_users => 'Coocook::Schema::Result::GroupUser' );
__PACKAGE__->many_to_many( users => groups_users => 'user' );

around [ 'set_column', 'store_column' ] => sub {
    my ( $orig, $self, $column => $value ) = @_;

    if ( $column eq 'name' ) {
        $self->$orig( name_fc => fc($value) );
    }

    return $self->$orig( $column => $value );
};

__PACKAGE__->meta->make_immutable;

sub has_project_role {
    my ( $self, $project, $role ) = @_;

    return $self->groups_projects->exists( { project => $project->id, role => $role } );
}

sub has_any_project_role {
    my $self    = shift;
    my $project = shift;

    my $roles = ( @_ == 1 and ref $_[0] eq 'ARRAY' ) ? $_[0] : \@_;

    return $self->groups_projects->exists( { project => $project->id, role => { -in => $roles } } );
}

1;
