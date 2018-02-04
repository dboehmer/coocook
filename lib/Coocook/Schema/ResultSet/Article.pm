package Coocook::Schema::ResultSet::Article;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components(
    '+Coocook::Schema::Component::ResultSet::ArticleOrUnit',
    '+Coocook::Schema::Component::ResultSet::SortByName',
);

__PACKAGE__->meta->make_immutable;

1;
