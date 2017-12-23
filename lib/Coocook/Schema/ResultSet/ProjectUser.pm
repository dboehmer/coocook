package Coocook::Schema::ResultSet::ProjectUser;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->meta->make_immutable;

=head2 owners()

Returns a new resultset with records where C<role> is C<owner>.

=cut

sub owners {
    my $self = shift;

    return $self->search( { $self->me('role') => 'owner' } );
}

1;
