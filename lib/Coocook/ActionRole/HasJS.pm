package Coocook::ActionRole::HasJS;

# ABSTRACT: role for controller actions to add page-specific JavaScript file

use Moose::Role;
use MooseX::MarkAsMethods autoclean => 1;

has js_path => (
    is  => 'rw',
    isa => 'Str',
);

after BUILD => sub {
    my ( $self, $args ) = @_;

    $self->js_path( '/js/' . $args->{reverse} . '.js' );

    # TODO check if file exists
};

before execute => sub {
    my ( $self, $controller, $c ) = @_;

    push @{ $c->stash->{js} }, $self->js_path;
};

1;
