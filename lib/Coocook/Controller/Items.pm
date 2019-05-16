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

sub unassigned : GET HEAD Chained('/purchase_list/submenu') PathPart('items/unassigned') Args(0)
  RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my $project = $c->project;

    my $lists = $project->search_related( purchase_lists => undef, { order_by => 'date' } );

    my @ingredients;

    {
        my $ingredients = $project->dish_ingredients->unassigned;

        my %articles = map { $_->id => $_ } $ingredients->search_related('article')->all;
        my %units    = map { $_->id => $_ } $ingredients->search_related('unit')->all;
        my %dishes =
          map { $_->id => $_ } $ingredients->search_related( dish => undef, { prefetch => 'meal' } )->all;

        @ingredients = $ingredients->search(
            undef,
            {
                join     => [ 'article', { 'dish' => 'meal' } ],
                order_by => [
                    qw<
                      meal.date
                      article.shop_section
                      article.name
                      >
                ],
            }
        )->hri->all;

        for my $ingredient (@ingredients) {
            $ingredient->{article} = $articles{ $ingredient->{article} };
            $ingredient->{unit}    = $units{ $ingredient->{unit} };
            $ingredient->{dish}    = $dishes{ $ingredient->{dish} };
        }
    }

    $c->stash(
        ingredients => \@ingredients,
        lists       => [ $lists->all ],
        assign_url  => $c->project_uri( $self->action_for('assign') ),
    );
}

sub assign : POST Chained('/project/base') PathPart('items/unassigned') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $ingredients = $c->project->dish_ingredients->unassigned;
    my %lists       = map { $_->id => $_ } $c->project->search_related('purchase_lists')->all;

    $ingredients->txn_do(
        sub {
            while ( my $ingredient = $ingredients->next ) {
                my $id = $ingredient->id;

                if ( my $list = $c->req->params->get("assign$id") ) {
                    $lists{$list} or $c->detach('/error/bad_request');

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

    my $item = $c->project->purchase_lists->search_related('items')->find($item_id)
      || $c->detach('/error/not_found');

    my $unit = $c->project->units->find( $c->req->params->get('unit') )
      || $c->detach('/error/not_found');

    $item->convert($unit);

    $c->response->redirect(
        $c->project_uri( '/purchase_list/edit', $item->get_column('purchase_list') ) );
}

__PACKAGE__->meta->make_immutable;

1;
