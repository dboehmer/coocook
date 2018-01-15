package Coocook::View::Email::Template;

# ABSTRACT: create e-mails with TT templates

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Catalyst::View::Email::Template';

=head1 NAME

Coocook::View::Email::Template - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=cut

__PACKAGE__->meta->make_immutable;

1;
