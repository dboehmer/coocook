package Coocook::Controller::Terms;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub index : GET HEAD Chained('/base') PathPart('terms') Args(0) Public {
    my ( $self, $c ) = @_;

    my $terms = $c->model('DB::Terms')->valid_today()
      or $c->detach('/error/not_found');

    $c->response->redirect( $c->uri_for( $self->action_for('show'), $terms->id ) );
}

sub show : GET HEAD Chained('/base') PathPart('terms') Args(1) Public {
    my ( $self, $c, $id ) = @_;

    my $terms = $c->model('DB::Terms')->find($id)
      or $c->detach('/error/not_found');

    if ( my $previous = $terms->previous ) {
        $c->stash( previous_url => $c->uri_for( $self->action_for('show'), $previous->id ) );
    }

    if ( my $next = $terms->next ) {
        $c->stash( next_url => $c->uri_for( $self->action_for('show'), $next->id ) );
    }

    $c->stash(
        title => "Terms",
        terms => $terms,
    );
}

__PACKAGE__->meta->make_immutable;

1;
