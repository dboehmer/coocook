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

sub unassigned : Local Args(0) {
    my ( $self, $c ) = @_;

    my $project = $c->stash->{my_project};
    my $ingredients =
      $c->model('Schema::Meal')->search( { project => $project->id } )
      ->dishes->ingredients->unassigned->search(
        undef,
        {
            prefetch => [qw<unit article>],
            order_by => [
                qw<
                  article.name
                  unit.short_name
                  value
                  >
            ],
        }
      );

    my $lists = $c->model('Schema::PurchaseList')->search(
        {
            project => $c->stash->{my_project}->id,
        },
        {
            order_by => 'date',
        }
    );

    $c->stash(
        ingredients => $ingredients,
        lists       => [ $lists->all ],
    );
}

sub assign : Local Args(0) POST {
    my ( $self, $c ) = @_;

    $c->forward('unassigned');

    my %lists = map { $_->id => $_ } @{ $c->stash->{lists} };

    $c->model('Schema')->schema->txn_do(    # TODO txn useful if single assignment fails?
        sub {
            while ( my $ingredient = $c->stash->{ingredients}->next ) {
                my $id = $ingredient->id;

                if ( my $list = scalar $c->req->param("assign$id") ) {
                    $ingredient->assign_to_purchase_list($list);
                }
            }
        }
    );

    $c->response->redirect( $c->uri_for_action( $self->action_for('unassigned') ) );
}

sub convert : Local POST Args(2) {
    my ( $self, $c, $item_id => $unit_id ) = @_;

    my $item = $c->model('Schema::Item')->find($item_id);
    my $unit = $c->model('Schema::Unit')->find($unit_id);

    $item->convert($unit);

    $c->response->redirect(
        $c->uri_for_action( '/purchase_list/edit', $item->get_column('purchase_list') ) );
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
