package Coocook::Controller::PurchaseList;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => 'purchase_list' );

=head1 NAME

Coocook::Controller::PurchaseList - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : GET Chained('/project/base') PathPart('purchase_lists') Args(0) {
    my ( $self, $c ) = @_;

    my $lists = $c->project->purchase_lists;

    my $max_date = do {
        my $list = $lists->search( undef, { columns => 'date', order_by => { -desc => 'date' } } )->first;

        $list ? $list->date : undef;
    };

    my $default_date =
        $max_date
      ? $max_date->add( days => 1 )
      : DateTime->today;

    $c->stash(
        default_date => $default_date,
        lists        => [ $lists->sorted->all ],
        title        => "Purchase lists",
    );
}

sub base : Chained('/project/base') PathPart('purchase_list') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( list => $c->project->purchase_lists->find($id) );    # TODO error handling
}

sub edit : GET Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $list = $c->model('PurchaseList')->new( list => $c->stash->{list} );

    $c->stash(
        sections => $list->shop_sections,
        units    => $list->units,
    );

    $c->escape_title( "Purchase list" => $c->stash->{list}->name );
}

sub create : POST Chained('/project/base') PathPart('purchase_lists/create') Args(0) {
    my ( $self, $c ) = @_;

    $c->project->create_related(
        purchase_lists => {
            date => scalar $c->req->param('date'),
            name => scalar $c->req->param('name'),
        }
    );

    $c->detach('redirect');
}

sub update : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{list}->update(
        {
            name => scalar $c->req->param('name'),
        }
    );

    $c->detach('redirect');
}

sub delete : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{list}->delete();

    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->project_uri( $self->action_for('index') ) );
}

__PACKAGE__->meta->make_immutable;

1;
