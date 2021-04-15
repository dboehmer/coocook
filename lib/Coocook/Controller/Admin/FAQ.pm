package Coocook::Controller::Admin::FAQ;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub index : GET HEAD Chained('/admin/base') PathPart('faq') Args(0)
  RequiresCapability('manage_faqs') {
    my ( $self, $c ) = @_;

    my @faqs = $c->model('DB::FAQ')->hri->all;

    for my $faq (@faqs) {
        $faq->{url} = $c->uri_for( $self->action_for('edit'), [ $faq->{id} ] );
    }

    $c->stash(
        faqs        => \@faqs,
        new_faq_url => $c->uri_for( $self->action_for('new_faq') ),
    );
}

sub new_faq : GET HEAD Chained('/admin/base') PathPart('faq/new') RequiresCapability('manage_faqs')
{
    my ( $self, $c ) = @_;

    $c->stash(
        admin_faq_url => $c->uri_for( $self->action_for('index') ),
        submit_url    => $c->uri_for( $self->action_for('create') ),
        template      => 'admin/faq/edit.tt',
    );
}

sub base : Chained('/admin/base') PathPart('faq') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    my $faq = $c->model('DB::FAQ')->find($id)
      or $c->detach('/error/not_found');

    $c->stash( faq => $faq );
}

sub edit : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('manage_faqs') {
    my ( $self, $c ) = @_;

    $c->stash->{faq}{url} = $c->uri_for_action( '/faq/index', \$c->stash->{faq}->anchor );

    $c->stash(
        admin_faq_url => $c->uri_for( $self->action_for('index') ),
        submit_url    => $c->uri_for( $self->action_for('update'), [ $c->stash->{faq}->id ] ),
    );
}

sub update : POST Chained('base') Args(0) RequiresCapability('manage_faqs') {
    my ( $self, $c ) = @_;

    $c->detach('update_or_create');
}

sub create : POST Chained('/admin/base') PathPart('faq/create') Args(0)
  RequiresCapability('manage_faqs') {
    my ( $self, $c ) = @_;

    $c->stash( faq => $c->model('DB::FAQ')->new_result( {} ) );

    $c->detach('update_or_create');
}

sub update_or_create : Private {
    my ( $self, $c ) = @_;

    my $faq = $c->stash->{faq};

    $faq->set_columns(
        {
            anchor      => $c->req->params->get('anchor'),
            question_md => $c->req->params->get('question'),
            answer_md   => $c->req->params->get('answer'),
        }
    );

    $faq->update_or_insert();

    $c->redirect_detach( $c->uri_for( $self->action_for('edit'), [ $faq->id ] ) );
}

__PACKAGE__->meta->make_immutable;

1;
