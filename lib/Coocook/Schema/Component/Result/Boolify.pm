package Coocook::Schema::Component::Result::Boolify;

use strict;
use warnings;

use parent 'DBIx::Class::FilterColumn';

my $BOOL_RE = qr/^bool$/i;

sub add_columns {
    my $class = shift;

    my $column_name;
    my @bool_columns;

    for (@_) {
        if ( ref eq 'HASH' ) {
            if ( $_->{data_type} =~ $BOOL_RE ) {
                push @bool_columns,
                  $column_name || die "hashref as first argument";
            }
        }
        else {
            $column_name = $_;
        }
    }

    my @ret = $class->next::method(@_);

    $class->filter_column( $_ => { filter_to_storage => 'to_bool' } )
      for @bool_columns;

    return @ret;
}

sub to_bool {
    my ( $self, $value ) = @_;

    return $value ? '1' : '0';
}

1;
