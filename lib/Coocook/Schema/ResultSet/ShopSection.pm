package Coocook::Schema::ResultSet::ShopSection;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::SortByName');

__PACKAGE__->meta->make_immutable;

sub with_article_count {
    my $self = shift;

    return $self->search_rs(
        undef,
        {
            '+columns' => { article_count => $self->correlate('articles')->count_rs->as_query },
        }
    );
}

1;
