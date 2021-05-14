package Coocook::ActionRole::Ajax;

# ABSTRACT: role for controller actions that respond with JSON and require a Session

use Moose::Role;
use MooseX::MarkAsMethods autoclean => 1;

before execute => sub {
    my ( $self, $controller, $c ) = @_;

    $c->stash( current_view => 'JSON' );
};

1;
