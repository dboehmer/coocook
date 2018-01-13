package Coocook::Controller;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

# TODO is this the best way to apply ActionRole::RequiresCapability?
sub COMPONENT {
    my ( $class, $app, $args ) = @_;

    $class->config( action_roles => ['~RequiresCapability'] );

    return $class->new( $app, $args );
}

__PACKAGE__->meta->make_immutable;

1;
