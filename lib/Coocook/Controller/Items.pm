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
      ->dishes->ingredients->unassigned;

    my $lists = $c->model('Schema::PurchaseList')
      ->search( undef, { order_by => 'date' } );

    $c->stash(
        ingredients => $ingredients,
        lists       => [ $lists->all ],
    );
}

sub assign : Local Args(0) POST {
    my ( $self, $c ) = @_;

    $c->forward('unassigned');

    my %lists = map { $_->id => $_ } @{ $c->stash->{lists} };

    $c->model('Schema')->schema->txn_do(
        sub {
            while ( my $ingredient = $c->stash->{ingredients}->next ) {
                if ( my $id =
                    scalar $c->req->param( 'assign' . $ingredient->id ) )
                {
                    $c->model('Schema::Item')->create(
                        {
                            purchase_list => $id,
                            value         => $ingredient->value,
                            unit          => $ingredient->unit,
                            article       => $ingredient->article,
                            comment       => "",
                            ingredients_items =>
                              [ { ingredient => $ingredient->id }, ],
                        }
                    );
                }
            }
        }
    );

    $c->response->redirect(
        $c->uri_for_action( $self->action_for('unassigned') ) );
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
