package Coocook::Controller::Items;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Items - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub unassigned : GET Chained('/project/base') PathPart('items/unassigned') Args(0) {
    my ( $self, $c ) = @_;

    my $project = $c->project;

    my $ingredients = $project->meals->dishes->ingredients->unassigned->search(
        undef,
        {
            prefetch => [ 'article', { 'dish' => 'meal' }, 'unit' ],
            order_by => [
                qw<
                  article.shop_section
                  article.name
                  meal.date
                  >
            ],
        }
    );

    my $lists = $project->purchase_lists->search(
        undef,
        {
            order_by => 'date',
        }
    );

    $c->stash(
        ingredients => [ $ingredients->all ],
        lists       => [ $lists->all ],
    );
}

sub assign : POST Chained('/project/base') PathPart('items/unassigned') Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('unassigned');

    my %lists = map { $_->id => $_ } @{ $c->stash->{lists} };

    $c->model('DB')->schema->txn_do(    # TODO txn useful if single assignment fails?
        sub {
            for my $ingredient ( @{ $c->stash->{ingredients} } ) {
                my $id = $ingredient->id;

                if ( my $list = scalar $c->req->param("assign$id") ) {
                    $ingredient->assign_to_purchase_list($list);
                }
            }
        }
    );

    $c->response->redirect( $c->project_uri( $self->action_for('unassigned') ) );
}

sub convert : POST Chained('/project/base') PathPart('items/convert') Args(1) {
    my ( $self, $c, $item_id ) = @_;

    my $item = $c->project->purchase_lists->items->find($item_id);    # TODO error handling

    my $unit = $c->project->units->find( scalar $c->req->param('unit') );    # TODO error handling

    $item->convert($unit);

    $c->response->redirect(
        $c->project_uri( '/purchase_list/edit', $item->get_column('purchase_list') ) );
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
