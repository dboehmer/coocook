package Coocook::Schema::Result;

# ABSTRACT: base class for all Result classes

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::NonMoose;

extends 'DBIx::Class::Core';

__PACKAGE__->load_components(
    qw<
      InflateColumn::DateTime
      +Coocook::Schema::Component::ProxyMethods
      +Coocook::Schema::Component::Result::Boolify
      >
);

=head2 as_hashref(%extra_kv_pairs?)

Returns a hashref with all column values from the object, possibly with additional hash key/value pairs.

    $c->stash( my_result => $result_object->as_hashref( url => $c->uri_for( ... ) ) );

=cut

sub as_hashref {
    my $self = shift;

    # TODO is there a method for getting a hashref right away?
    return { $self->get_inflated_columns, @_ };
}

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
