package Coocook::View::TT;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    ENCODING           => 'utf-8',
    INCLUDE_PATH       => Coocook->path_to(qw<root templates>),
    WRAPPER            => 'wrapper.tt',
    TEMPLATE_EXTENSION => '.tt',
    render_die         => 1,
);

=head1 NAME

Coocook::View::TT - TT View for Coocook

=head1 DESCRIPTION

TT View for Coocook.

=head1 SEE ALSO

L<Coocook>

=head1 AUTHOR

Daniel Böhmer,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
