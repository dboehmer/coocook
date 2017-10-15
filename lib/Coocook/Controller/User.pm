package Coocook::Controller::User;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

Coocook::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub show : GET Path Args(1) {
    my ( $self, $c, $name ) = @_;

    my $user = $c->model('DB::User')->find( { name => $name } );

    $c->stash(
        user     => $user,
        projects => [ $user->projects->all ],
    );

    $c->escape_title( User => $user->display_name );
}

__PACKAGE__->meta->make_immutable;

1;
