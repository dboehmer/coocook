package Coocook::View::Email::TT;

# ABSTRACT: helper view for Coocook::View::Email to render TT templates

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::NonMoose;

extends 'Catalyst::View::TT';

around render => sub {
    my $orig = shift;
    my $self = shift;
    my ( $c, $template, $args ) = @_;

    my $output = $self->$orig(@_);

    $c->log->info(
        sprintf( "Sending email to <%s> with subject '%s'", $args->{email}{to}, $args->{email}{subject} ) );

    return $output;
};

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
