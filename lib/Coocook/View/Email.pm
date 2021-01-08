package Coocook::View::Email;

# ABSTRACT: create emails with TT templates

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

    my $stash = $c->stash->{ $self->stash_key };

    # automatically set template filename based on action path
    $stash->{template} ||= do {
        my $action = $c->action;
        $action =~ s!^email/!!
          or warn "Unexpected action '$action'";

        $action . '.tt';
    };
};

around generate_message => sub {
    my $orig = shift;
    my $self = shift;
    my $attr = $_[1];

    # workaround for https://github.com/dboehmer/coocook/issues/139
    # be more specific what kind of header we have
    # https://metacpan.org/pod/release/RJBS/Email-MIME-1.949/lib/Email/MIME.pm#header
    $attr->{header_str} = delete $attr->{header};

    return $self->$orig(@_);
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
