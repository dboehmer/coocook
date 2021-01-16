package Coocook::Schema::Component::Result::Boolify;

# ABSTRACT: always save value for bool columns as 1 or 0

use strict;
use warnings;

use parent 'DBIx::Class::FilterColumn';

my $to_bool = sub { $_[1] ? 1 : 0 };

sub register_column {
    my $class = shift;
    my ( $column_name, $column_info ) = @_;

    if ( $column_info->{data_type} eq 'boolean' ) {
        $class->filter_column( $column_name => { filter_to_storage => $to_bool } );
    }

    return $class->next::method(@_);
}

1;
