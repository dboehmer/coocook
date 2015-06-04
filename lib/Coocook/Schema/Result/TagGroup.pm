package Coocook::Schema::Result::TagGroup;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("tag_groups");

__PACKAGE__->add_columns(
    id    => { data_type => "int", is_auto_increment => 1 },
    color => { data_type => "int", is_nullable       => 1 },
    name  => { data_type => "text" },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( ['name'] );

__PACKAGE__->has_many( tags => 'Coocook::Schema::Result::Tag' => 'tag_group' );

__PACKAGE__->meta->make_immutable;

sub deletable {
    my $self = shift;

    return ( $self->tags->count <= 0 );
}

1;
