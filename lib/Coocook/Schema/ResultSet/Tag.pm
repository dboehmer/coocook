package Coocook::Schema::ResultSet::Tag;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

sub joined {
    my $self = shift;

    return join " ", $self->get_column('name')->all;
}

sub from_names {
    my ( $self, $str ) = @_;

    my @names = split qr/\s+/, $str;

    return $self->search(
        {
            name => { -in => \@names },
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
