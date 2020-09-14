package Coocook::ActionRole::HasCSS;

# ABSTRACT: role for controller actions to add page-specific CSS file

use Moose::Role;
use MooseX::MarkAsMethods autoclean => 1;

has css_path => (
    is  => 'rw',
    isa => 'Str',
);

after BUILD => sub {
    my ( $self, $args ) = @_;

    $self->css_path( '/css/' . $args->{reverse} . '.css' );

    # TODO check if file exists
};

before execute => sub {
    my ( $self, $controller, $c ) = @_;

    push @{ $c->stash->{css} }, $self->css_path;
};

1;
