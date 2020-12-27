package Coocook::Schema::Result::TagGroup;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('tag_groups');

__PACKAGE__->add_columns(
    id         => { data_type => 'integer', is_auto_increment => 1 },
    project_id => { data_type => 'integer' },
    color      => { data_type => 'integer', is_nullable => 1 },
    name       => { data_type => 'text' },
    comment    => { data_type => 'text', default_value => '' },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( [ 'project_id', 'name' ] );

__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project', 'project_id' );

__PACKAGE__->has_many(
    tags => 'Coocook::Schema::Result::Tag' => 'tag_group_id',
    {
        cascade_delete => 0,    # tag groups with tags may not be deleted
    }
);

__PACKAGE__->has_many(
    tags_sorted => 'Coocook::Schema::Result::Tag' => 'tag_group_id',
    {
        cascade_delete => 0,        # see above
        order_by       => 'name',
    }
);

__PACKAGE__->meta->make_immutable;

sub deletable {
    my $self = shift;

    return !$self->tags->results_exist;
}

1;
