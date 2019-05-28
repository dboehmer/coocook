package Coocook::View::HTML;

# ABSTRACT: view for Coocook to create HTML pages with Template Toolkit

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::NonMoose;

extends 'Catalyst::View::TT';

__PACKAGE__->meta->make_immutable;

__PACKAGE__->config(
    ENCODING           => 'utf-8',
    PLUGIN_BASE        => 'Coocook::Filter',
    PRE_PROCESS        => 'macros.tt',
    WRAPPER            => 'wrapper.tt',
    TEMPLATE_EXTENSION => '.tt',
    render_die         => 1,
);

1;
