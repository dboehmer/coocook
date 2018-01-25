package Coocook::Controller::PurchaseList;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

__PACKAGE__->config( namespace => 'purchase_list' );

=head1 NAME

Coocook::Controller::PurchaseList - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : GET HEAD Chained('/project/base') PathPart('purchase_lists') Args(0)
  RequiresCapability('view_project') {
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

sub edit : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $list = $c->model('PurchaseList')->new( list => $c->stash->{list} );

    $c->stash(
        sections => $list->shop_sections,
        units    => $list->units,
    );

    for my $sections ( @{ $c->stash->{sections} } ) {
        for my $item ( @{ $sections->{items} } ) {
            for my $ingredient ( @{ $item->{ingredients} } ) {
                $ingredient->{remove_url} =
                  $c->project_uri( '/purchase_list/remove_ingredient', $ingredient->{id} );
            }
        }
    }

    $c->escape_title( "Purchase list" => $c->stash->{list}->name );
}

sub remove_ingredient : POST Chained('/project/base') PathPart('purchase_list/remove_ingredient')
  Args(1) RequiresCapability('edit_project') {
    my ( $self, $c, $ingredient_id ) = @_;

    my $ingredient = $c->project->dishes->ingredients->find($ingredient_id)
      or die "ingredient not found";

    my $item = $ingredient->item
      or die "item not found";

    $ingredient->remove_from_purchase_list();

    $c->response->redirect(
        $c->project_uri( $self->action_for('edit'), $item->get_column('purchase_list') ) );
}

sub create : POST Chained('/project/base') PathPart('purchase_lists/create') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->project->create_related(
        purchase_lists => {
            date => $c->req->params->get('date'),
            name => $c->req->params->get('name'),
        }
    );

    $c->detach('redirect');
}

sub update : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->stash->{list}->update(
        {
            name => $c->req->params->get('name'),
        }
    );

    $c->detach('redirect');
}

sub delete : POST Chained('base') Args(0) RequiresCapability('edit_project') {
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
