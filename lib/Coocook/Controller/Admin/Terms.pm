package Coocook::Controller::Admin::Terms;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use DateTime;

BEGIN { extends 'Coocook::Controller' }

sub index : GET HEAD Chained('/admin/base') PathPart('terms') Args(0)
  RequiresCapability('manage_terms') {
    my ( $self, $c ) = @_;

    my @terms;

    for my $terms ( $c->model('DB::Terms')->order(+1)->all ) {
        my %terms = (
            valid_from => $terms->get_column('valid_from'),
            content_md => $terms->get_column('content_md'),
        );

        $terms{view_url} = $c->uri_for_action( '/terms/show', [ $terms->id ] );

        $terms->reasons_to_freeze
          or $terms{edit_url} = $c->uri_for( $self->action_for('edit'), [ $terms->id ] );

        $terms->reasons_to_keep
          or $terms{delete_url} = $c->uri_for( $self->action_for('delete'), [ $terms->id ] );

        push @terms, \%terms;
    }

    $c->stash(
        terms   => \@terms,
        new_url => $c->uri_for( $self->action_for('new_terms') ),
    );
}

sub new_terms : GET HEAD Chained('/admin/base') PathPart('terms/new')
  RequiresCapability('manage_terms') {
    my ( $self, $c ) = @_;

    my $default_offset_days = 31;    # TODO allow configuration

    my $default_date = do {
        my $newest = $c->model('DB::Terms')->order(-1)->one_row;
        $newest ? $newest->valid_from : DateTime->today;
    };
    $default_date->add( days => $default_offset_days );

    my $terms = $c->model('DB::Terms')->new_result( { valid_from => $default_date } );

    $c->stash(
        submit_url => $c->uri_for( $self->action_for('create') ),
        terms      => $terms,
    );

    $c->detach('edit');
}

sub base : Chained('/admin/base') PathPart('terms') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    my $terms = $c->model('DB::Terms')->find($id)
      or $c->detach('/error/not_found');

    $c->stash( terms => $terms );
}

sub delete : POST Chained('base') PathPart('delete') Args(0) RequiresCapability('manage_terms') {
    my ( $self, $c ) = @_;

    my $terms = $c->stash->{terms};

    $c->detach('/error/bad_request')
      if $terms->reasons_to_keep;

    $terms->delete();

    $c->redirect_detach( $c->uri_for( $self->action_for('index') ) );
}

sub edit : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('manage_terms') {
    my ( $self, $c ) = @_;

    $c->stash->{submit_url} ||=    # in case of /new
      $c->uri_for( $self->action_for('update'), [ $c->stash->{terms}->id ] );

    $c->stash(
        tomorrow => DateTime->today->add( days => 1 ),
        template => 'admin/terms/edit.tt',               # in case of /new
    );
}

sub update : POST Chained('base') Args(0) RequiresCapability('manage_terms') {
    my ( $self, $c ) = @_;

    $c->detach('update_or_create');
}

sub create : POST Chained('/admin/base') PathPart('terms/create') Args(0)
  RequiresCapability('manage_terms') {
    my ( $self, $c ) = @_;

    $c->stash( terms => $c->model('DB::Terms')->new_result( {} ) );

    $c->detach('update_or_create');
}

sub update_or_create : Private {
    my ( $self, $c ) = @_;

    my $terms = $c->stash->{terms};

    $terms->set_columns(
        {
            valid_from => $c->req->params->get('valid_from'),    # TODO validate
            content_md => $c->req->params->get('content_md'),
        }
    );

    if ( $terms->in_storage ) {
        $terms->update();
        $c->redirect_detach( $c->uri_for( $self->action_for('edit'), [ $terms->id ] ) );
    }
    else {
        $terms->insert();
        $c->redirect_detach( $c->uri_for( $self->action_for('index') ) );
    }
}

__PACKAGE__->meta->make_immutable;

1;
