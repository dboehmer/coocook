package Coocook::Schema::ResultSet::Item;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

# find item and add value or create new item with value
sub add_or_create {
    my ( $self, $args ) = @_;

    my $item = $self->find_or_new(
        {
            purchase_list_id => $args->{purchase_list_id},
            article_id       => $args->{article_id},
            unit_id          => $args->{unit_id},
        }
    );

    if ( $item->in_storage ) {
        $item->value( $item->value + $args->{value} );
    }
    else {
        $item->set_columns(
            {
                value   => $args->{value},
                comment => "",               # no argument because existing items have comments
                offset  => 0,                # instantly apply default_value
            }
        );
    }

    $item->update_or_insert and return $item;
}

__PACKAGE__->meta->make_immutable;

1;
