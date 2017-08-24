package Coocook::Schema::Result;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::NonMoose;

extends 'DBIx::Class::Core';

__PACKAGE__->load_components(
    qw<
      InflateColumn::DateTime
      +Coocook::Schema::Component::Result::Boolify
      >
);

# set default of cascade_copy to false
sub has_many {
    my $class = shift;

    if ( @_ >= 4 ) {
        my $attrs = $_[3];

        if ( ref $attrs eq 'HASH' ) {
            if ( not defined $attrs->{cascade_copy} ) {
                $_[3] = { %$attrs, cascade_copy => 0 };    # replace with changed hash
            }
        }
        else {
            die "argument type not supported";
        }
    }
    else {
        $_[3] = { cascade_copy => 0 };
    }

    return $class->SUPER::has_many(@_);
}

__PACKAGE__->meta->make_immutable;

1;
