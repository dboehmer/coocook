package Coocook::ActionRole::RequiresCapability;

# ABSTRACT: role for controller action to assert Model::Authz grants capability

use Coocook::Model::Authorization;
use Moose::Role;
use MooseX::MarkAsMethods autoclean => 1;

after BUILD => sub {
    my ( $class, $args ) = @_;

    if ( my $capabilities = $args->{attributes}{RequiresCapability} ) {
        @$capabilities <= 1
          or warn
          "You should define a new capability instead of requiring multiple capabilities for action "
          . $args->{reverse};

        for my $capability (@$capabilities) {
            Coocook::Model::Authorization->capability_exists($capability)
              or die "Invalid capability '$capability' in RequiresCapability() for action $args->{reverse}";
        }
    }
};

around execute => sub {
    my $orig = shift;
    my $self = shift;
    my ( $controller, $c ) = @_;

    if ( my $capabilities = $self->attributes->{RequiresCapability} ) {
        $c->require_capability( $_, $c->stash ) for @$capabilities;
    }

    $self->$orig(@_);
};

1;
