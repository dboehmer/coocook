package Coocook::Controller::Project::PurchaseList;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

# Catalyst compiles PurchaseList into purchaselist
__PACKAGE__->config( namespace => 'project/purchase_list' );

=head1 NAME

Coocook::Controller::Project::PurchaseList - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub submenu : Chained('/project/base') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        submenu_items => [
            { text => "Purchase lists",   action => 'purchase_list/index' },
            { text => "Unassigned items", action => 'item/unassigned' },
            { text => "Shop sections",    action => 'shop_section/index' },
            { text => "Printing",         action => 'print/index' },
        ]
    );
}

=head2 index

=cut

sub index : GET HEAD Chained('submenu') PathPart('purchase_lists') Args(0)
  RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my $lists = $c->project->purchase_lists;

    my $today    = DateTime->today;
    my $min_date = $today;

    my $default_date = do {    # one day after today or last list's date
        my $last_list =
          $lists->search( undef, { columns => 'date', order_by => { -desc => 'date' } } )->one_row;

        my $date =
          ( $last_list and $today < $last_list->date )
          ? $last_list->date
          : $today->clone;

        $date->add( days => 1 );
    };

    my @lists = $lists->sorted->with_item_count->hri->all;

    for my $list (@lists) {
        $list->{date} = $lists->parse_date( $list->{date} );

        $list->{edit_url}   = $c->project_uri( $self->action_for('edit'),   $list->{id} );
        $list->{update_url} = $c->project_uri( $self->action_for('update'), $list->{id} );
        $list->{delete_url} = $c->project_uri( $self->action_for('delete'), $list->{id} );
    }

    $c->stash(
        default_date => $default_date,
        min_date     => $min_date,
        lists        => \@lists,
        create_url   => $c->project_uri( $self->action_for('create') ),
    );
}

sub base : Chained('submenu') PathPart('purchase_list') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( lists => my $lists = $c->project->purchase_lists );
    $c->stash( list  => $lists->find($id) || $c->detach('/error/not_found') );
}

sub edit : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my $list = $c->model('PurchaseList')->new( list => $c->stash->{list} );

    $c->stash(
        sections => $list->shop_sections,
        units    => $list->units,
    );

    $c->has_capability('edit_project')
      or return;

    for my $sections ( @{ $c->stash->{sections} } ) {
        for my $item ( @{ $sections->{items} } ) {
            $item->{convert_url} = $c->project_uri( '/project/item/convert', $item->{id} );

            $item->{update_offset_url} = $c->project_uri( '/project/item/update_offset', $item->{id} );

            for my $ingredient ( @{ $item->{ingredients} } ) {
                $ingredient->{remove_url} =
                  $c->project_uri( '/project/purchase_list/remove_ingredient', $ingredient->{id} );
            }
        }
    }
}

sub remove_ingredient : POST Chained('/project/base') PathPart('purchase_list/remove_ingredient')
  Args(1) RequiresCapability('edit_project') {
    my ( $self, $c, $ingredient_id ) = @_;

    my $ingredient = $c->project->dishes->search_related('ingredients')->find($ingredient_id)
      or die "ingredient not found";

    my $item = $ingredient->item
      or die "item not found";

    $ingredient->remove_from_purchase_list();

    $c->response->redirect( $c->project_uri( $self->action_for('edit'), $item->purchase_list_id ) );
}

sub create : POST Chained('/project/base') PathPart('purchase_lists/create') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $date = $c->req->params->get('date')
      or $c->detach('/error/bad_request');

    # TODO parse and verify date

    $c->stash( lists => my $lists = $c->project->purchase_lists );
    $c->stash( list  => $lists->new_result( { date => $date } ) );

    $c->detach('update');
}

sub update : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $name = $c->req->params->get('name') // $c->detach('/error/bad_request');

    if ( $name !~ m/\w/ ) {
        $c->messages->error("The name of a purchase list must not be empty!");
        $c->detach('redirect');
    }

    my $list  = $c->stash->{list};
    my $lists = $c->stash->{lists};

    # exclude this very list from duplicate search
    if ( my $id = $list->id ) {
        $lists = $lists->search( { id => { '!=' => $id } } );
    }

    if ( $lists->search( { name => $name } )->results_exist ) {
        $c->messages->error("A purchase list with that name already exists!");
        $c->detach('redirect');
    }

    $list->name($name);
    $list->update_or_insert();

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
