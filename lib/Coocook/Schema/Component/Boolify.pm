package Coocook::Schema::Component::Boolify;

use Moose;

extends 'DBIx::Class::FilterColumn';

sub boolify {
    my $class = shift;

    for my $column (@_) {
        $class->filter_column( $column => { filter_to_storage => 'to_bool' } );
    }
}

sub to_bool {
    my ( $self, $value ) = @_;

    return $value ? '1' : '0';
}

1;
