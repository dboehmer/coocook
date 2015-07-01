package Coocook::Schema::Result::ArticleTag;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("articles_tags");

__PACKAGE__->add_columns(
    article => { data_type => 'int' },
    tag     => { data_type => 'int' },
);

__PACKAGE__->set_primary_key(qw<article tag>);

__PACKAGE__->belongs_to( article => 'Coocook::Schema::Result::Article' );
__PACKAGE__->belongs_to( tag     => 'Coocook::Schema::Result::Tag' );

__PACKAGE__->meta->make_immutable;

1;
