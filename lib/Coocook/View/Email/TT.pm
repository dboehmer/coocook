package Coocook::View::Email::TT;

# ABSTRACT: helper view for Coocook::View::Email to render TT templates

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::NonMoose;

extends 'Catalyst::View::TT';

__PACKAGE__->meta->make_immutable;

__PACKAGE__->config(
    ENCODING           => 'utf-8',
    PLUGIN_BASE        => 'Coocook::Filter',
    WRAPPER            => 'wrapper.tt',
    TEMPLATE_EXTENSION => '.tt',
    render_die         => 1,
);

1;
