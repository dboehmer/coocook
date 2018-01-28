package Coocook::Controller::Items;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Items - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub unassigned : GET HEAD Chained('/project/base') PathPart('items/unassigned') Args(0)
  RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my $project = $c->project;

    my $ingredients =
      $project->meals->search_related('dishes')->search_related('ingredients')->unassigned->search(
        undef,
        {
            prefetch => [ 'article', { 'dish' => 'meal' }, 'unit' ],
            order_by => [
                qw<
                  meal.date
                  article.shop_section
                  article.name
                  >
            ],
        }
      );

    my $lists = $project->search_related(
        'purchase_lists',
        undef,
        {
            order_by => 'date',
        }
    );

    $c->stash(
        ingredients => [ $ingredients->all ],
        lists       => [ $lists->all ],
        title       => "Unassigned items",
    );
}

sub assign : POST Chained('/project/base') PathPart('items/unassigned') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->forward('unassigned');

    my %lists = map { $_->id => $_ } @{ $c->stash->{lists} };

    $c->txn_do(
        sub {
            for my $ingredient ( @{ $c->stash->{ingredients} } ) {
                my $id = $ingredient->id;

                if ( my $list = $c->req->params->get("assign$id") ) {
                    $ingredient->assign_to_purchase_list($list);
                }
            }
        }
    );

    $c->response->redirect( $c->project_uri( $self->action_for('unassigned') ) );
}

sub convert : POST Chained('/project/base') PathPart('items/convert') Args(1)
  RequiresCapability('edit_project') {
    my ( $self, $c, $item_id ) = @_;

    my $item =
      $c->project->purchase_lists->search_related('items')->find($item_id);    # TODO error handling

    my $unit = $c->project->units->find( $c->req->params->get('unit') );       # TODO error handling

    $item->convert($unit);

    $c->response->redirect(
        $c->project_uri( '/purchase_list/edit', $item->get_column('purchase_list') ) );
}

__PACKAGE__->meta->make_immutable;

1;
