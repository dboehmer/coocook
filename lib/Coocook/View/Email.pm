package Coocook::View::Email;

# ABSTRACT: create e-mails with TT templates

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Catalyst::View::Email::Template';

=head1 NAME

Coocook::View::Email::Template - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=cut

before process => sub {
    my ( $self, $c ) = @_;

    my $stash_key = $self->stash_key;

    $c->log->info(
        sprintf(
            "Sending e-mail to <%s> with subject '%s'",
            $c->stash->{$stash_key}{to},
            $c->stash->{$stash_key}{subject},
        )
    );
};

__PACKAGE__->meta->make_immutable;

__PACKAGE__->config(
    default => {
        view => 'Email::TT',

        content_type => 'text/plain',
        charset      => 'utf-8',
        encoding     => 'quoted-printable',
    },
    sender => { mailer => $ENV{EMAIL_SENDER_TRANSPORT} || 'SMTP' },
);

1;
