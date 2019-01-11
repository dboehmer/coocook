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

sub submenu : Chained('/project/base') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        submenu_items => [
            { text => "Purchase lists",   action => 'purchase_list/index' },
            { text => "Unassigned items", action => 'items/unassigned' },
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

    my $min_date = DateTime->today;

    my $default_date = do {    # one day after today or last list's date
        my $date = $min_date;

        my $last_list =
          $lists->search( undef, { columns => 'date', order_by => { -desc => 'date' } } )->one_row;

        if ($last_list) {
            if ( $date < $last_list->date ) {
                $date = $last_list->date;
            }
        }

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

    $c->stash( list => $c->project->purchase_lists->find($id) || $c->detach('/error/not_found') );
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
            $item->{convert_url} = $c->project_uri( '/items/convert', $item->{id} );

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

    my $ingredient = $c->project->dishes->search_related('ingredients')->find($ingredient_id)
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

    my $date = $c->req->params->get('date');
    my $name = $c->req->params->get('name');

    my $lists = $c->project->search_related('purchase_lists');

    if ( $lists->search( { name => $name } )->exists ) {
        push @{ $c->stash->{errors} }, "A purchase list with that name already exists!";

        $c->stash(
            last_input => {
                date => $date,
                name => $name,
            }
        );

        $c->go( 'index', [ $c->project->url_name ], [] );
    }

    $c->project->create_related(
        purchase_lists => {
            date => $date,
            name => $name,
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
