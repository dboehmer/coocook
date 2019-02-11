package Coocook::Schema::Result::TagGroup;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("tag_groups");

__PACKAGE__->add_columns(
    id      => { data_type => 'int', is_auto_increment => 1 },
    project => { data_type => 'int' },
    color   => { data_type => 'int', is_nullable => 1 },
    name    => { data_type => 'text' },
    comment => { data_type => 'text', default_value => "" },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( [ 'project', 'name' ] );

__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project' );

__PACKAGE__->has_many( tags => 'Coocook::Schema::Result::Tag' => 'tag_group' );

__PACKAGE__->has_many(
    tags_sorted => 'Coocook::Schema::Result::Tag' => 'tag_group',
    { order_by => 'name' }
);

__PACKAGE__->meta->make_immutable;

sub deletable {
    my $self = shift;

    return !$self->tags->exists;
}

1;
