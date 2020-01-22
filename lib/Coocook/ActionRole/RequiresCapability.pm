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
        for my $capability (@$capabilities) {
            next if $c->has_capability( $capability, $c->stash );

            # not logged in? try login and redirect here again
            if ( $c->req->method eq 'GET' and not $c->user ) {
                $c->redirect_detach( $c->redirect_uri_for_action('/session/login') );
            }

            $c->detach('/error/forbidden');
        }
    }

    $self->$orig(@_);
};

1;
