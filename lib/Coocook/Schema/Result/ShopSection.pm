package Coocook::Schema::Result::ShopSection;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("shop_sections");

__PACKAGE__->add_columns(
    id      => { data_type => 'int', is_auto_increment => 1 },
    project => { data_type => 'int' },
    name    => { data_type => 'text' },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( [ 'project', 'name' ] );

__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project' );

__PACKAGE__->has_many(
    articles => 'Coocook::Schema::Result::Article',
    'shop_section'
);

__PACKAGE__->meta->make_immutable;

sub deletable {
    my $self = shift;

    if ( defined( my $count = $self->get_column('article_count') ) ) {
        return $count == 0;
    }
    else {
        return !$self->articles->exists;
    }
}

1;
