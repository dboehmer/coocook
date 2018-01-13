package Coocook::ActionRole::RequiresCapability;

use Moose::Role;
use MooseX::MarkAsMethods autoclean => 1;

around execute => sub {
    my $orig = shift;
    my $self = shift;
    my ( $controller, $c ) = @_;

    if ( my $capabilities = $self->attributes->{RequiresCapability} ) {
        @$capabilities <= 1
          or warn "You should define a new capability instead of requiring multiple capabilities";

        for my $capability (@$capabilities) {
            $c->has_capability($capability)
              or $c->detach('/error/forbidden');
        }
    }

    $self->$orig(@_);
};

1;
