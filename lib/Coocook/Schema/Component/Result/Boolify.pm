package Coocook::Schema::Component::Result::Boolify;

# ABSTRACT: always save value for bool columns as 1 or 0

use strict;
use warnings;

use parent 'DBIx::Class::FilterColumn';

my $BOOL_RE = qr/^bool(?:ean)?$/i;

sub register_column {
    my $class = shift;
    my ( $column_name, $column_info ) = @_;

    if ( $column_info->{data_type} =~ $BOOL_RE ) {
        $class->filter_column( $column_name => { filter_to_storage => 'to_bool' } );
    }

    return $class->next::method(@_);
}

sub to_bool {
    my ( $self, $value ) = @_;

    return $value ? 1 : 0;
}

1;
