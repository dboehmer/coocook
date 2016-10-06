package Coocook::Schema::ResultSet::Unit;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

sub sorted {
    my $self = shift;

    $self->search(
        undef,
        {
            order_by => $self->me('short_name'),
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
