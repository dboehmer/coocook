package Coocook::Controller::FAQ;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub index : GET HEAD Chained('/base') PathPart('faq') Args(0) {
    my ( $self, $c ) = @_;

    my @faqs = $c->model('DB::FAQ')->search( undef, { order_by => 'position' } )->hri->all;

    @faqs > 0
      or $c->detach('/error/not_found');

    $c->stash(
        title => "FAQ",
        faqs  => \@faqs,
    );
}

__PACKAGE__->meta->make_immutable;

1;
