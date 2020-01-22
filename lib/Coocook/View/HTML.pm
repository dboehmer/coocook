package Coocook::View::HTML;

# ABSTRACT: view for Coocook to create HTML pages with Template Toolkit

use Moose;

use HTML::Entities 'encode_entities';
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::NonMoose;

extends 'Catalyst::View::TT';

__PACKAGE__->meta->make_immutable;

__PACKAGE__->config(
    ENCODING           => 'utf-8',
    PLUGIN_BASE        => 'Coocook::Filter',
    PRE_PROCESS        => 'macros.tt',
    TEMPLATE_EXTENSION => '.tt',
    WRAPPER            => 'wrapper.tt',

    expose_methods => ['escape_title'],
    render_die     => 1,
);

=head2 escape_title( $title, $text )

Set C<< $stash->{title} >> and C<< $stash->{html_title} >> in 1 step.

    escape_title( User => $user->display_name ); # Cool guy :->
    # html_title: User <em>Cool guy:-&gt;</em>
    #      title: User "Cool guy:->"
    #             can be escaped with TT filter 'html' to: &quot;Cool guy:-&gt;&quot;

=cut

sub escape_title {
    my ( $self, $c, $title, $text ) = @_;

    $self->template->context->stash->update(
        {
            title      => qq($title "$text"),
            html_title => "$title <em>" . encode_entities($text) . "</em>",
        }
    );

    return;
}

1;
