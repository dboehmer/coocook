package Coocook::Controller::PurchaseList;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config( namespace => 'purchase_list' );

=head1 NAME

Coocook::Controller::PurchaseList - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path('/purchase_lists') {
    my ( $self, $c ) = @_;

    my $lists = $c->model('Schema::PurchaseList');

    $c->stash(
        default_date => DateTime->today,
        lists        => $c->model('Schema::PurchaseList'),
    );
}

sub edit : Path Args(1) {
    my ( $self, $c, $id ) = @_;

    my $list = $c->model('Schema::PurchaseList')->find($id);

    $c->stash( list => $list );
}

sub create : Local POST {
    my ( $self, $c ) = @_;

    $c->model('Schema::PurchaseList')->create(
        {
            date    => scalar $c->req->param('date'),
            name    => scalar $c->req->param('name'),
            project => scalar $c->req->param('project'),
        }
    );

    $c->detach('redirect');
}

sub update : Args(1) Local POST {
    my ( $self, $c, $id ) = @_;

    my $list = $c->model('Schema::PurchaseList')->find($id);

    $list->update(
        {
            name => scalar $c->req->param('name'),
        }
    );

    $c->detach('redirect');
}

sub delete : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;

    $c->model('Schema::PurchaseList')->find($id)->delete;

    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->uri_for_action( $self->action_for('index') ) );
}

=encoding utf8

=head1 AUTHOR

Daniel Böhmer,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
