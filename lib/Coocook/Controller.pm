package Coocook::Controller;

# ABSTRACT: base class for all controllers in Coocook

use Carp;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

# TODO is this the best way to apply action roles?
sub COMPONENT {
    my ( $class, $app, $args ) = @_;

    $class->config(
        action_roles => [    #perltidy
            ( $ENV{CATALYST_DEBUG} ? '~RequireHttpMethod' : () ),
            '~RequiresCapability',
        ]
    );

    return $class->new( $app, $args );
}

around action_for => sub {
    my $orig = shift;
    my $self = shift;

    my $action = $self->$orig(@_)
      or croak "No such action: @_";

    return $action;
};

__PACKAGE__->meta->make_immutable;

1;
