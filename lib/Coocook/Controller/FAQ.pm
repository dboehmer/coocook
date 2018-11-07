package Coocook::Controller::FAQ;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub index : GET HEAD Chained('/base') PathPart('faq') Args(0) {
    my ( $self, $c ) = @_;

    my @faqs = $c->model('DB::FAQ')->search( undef, { order_by => 'position' } )->hri->all;

    @faqs > 0
      or $c->detach('/error/not_found');

    if ( $c->has_capability('admin_view') ) {
        $c->stash( admin_faq_url => $c->uri_for_action('/admin/faq/index') );

        for my $faq (@faqs) {
            $faq->{edit_url} = $c->uri_for_action( '/admin/faq/edit', [ $faq->{id} ] );
        }
    }

    $c->stash(
        title => "FAQ",
        faqs  => \@faqs,
    );
}

__PACKAGE__->meta->make_immutable;

1;
