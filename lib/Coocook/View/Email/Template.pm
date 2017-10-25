package Coocook::View::Email::Template;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Catalyst::View::Email::Template';

=head1 NAME

Coocook::View::Email::Template - Catalyst View

=head1 DESCRIPTION

Catalyst View.


=encoding utf8

=head1 AUTHOR

Daniel Böhmer

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
