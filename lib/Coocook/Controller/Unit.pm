package Coocook::Controller::Unit;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use Scalar::Util qw(looks_like_number);

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Unit - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : GET HEAD Chained('/project/base') PathPart('units') Args(0)
  RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my @quantities =
      $c->project->quantities->sorted->search( undef, { prefetch => 'default_unit' } )->all;
    my %quantities = map { $_->id => $_ } @quantities;

    my %units_in_use;

    {
        my @resultsets = (
            $c->project->units->search_related('articles_units'),
            $c->project->purchase_lists->search_related('items'),
            $c->project->dishes->search_related('ingredients'),
            $c->project->recipes->search_related('ingredients'),
        );

        for my $resultset (@resultsets) {
            my $ids = $resultset->get_column( { distinct => 'unit' } );

            @units_in_use{ $ids->all } = ();    # set all keys to undef
        }
    }

    my @units;

    {
        my $action = $self->action_for('delete');

        my $units = $c->project->units->search( undef,
            { join => 'quantity', order_by => [ 'quantity.name', 'to_quantity_default', 'long_name' ] } );

        while ( my $unit = $units->next ) {
            $unit->quantity( $quantities{ $unit->get_column('quantity') } );

            my %unit = (
                url => $c->project_uri( $self->action_for('edit'), $unit->id ),
                from_quantity_default => $unit->to_quantity_default ? 1 / $unit->to_quantity_default : undef,
                map { $_ => $unit->$_() }
                  qw<
                  id
                  is_quantity_default
                  long_name
                  quantity
                  short_name
                  space
                  to_quantity_default
                  >
            );

            if ( $unit->quantity and not $unit->is_quantity_default ) {
                $unit{make_quantity_default_url} =
                  $c->project_uri( $self->action_for('make_quantity_default'), $unit{id} );
            }

            push @units, \%unit;

            # add delete_url to deletable units
            exists $units_in_use{ $unit->id }    # in use, for ingredient
              or (  $unit->is_quantity_default
                and $unit->convertible_into > 0 )    # need to make other unit quantity default
              or $unit{delete_url} = $c->project_uri( $action, $unit{id} );    # can be deleted
        }
    }

    $c->stash(
        create_url => $c->project_uri( $self->action_for('create') ),
        quantities => \@quantities,
        units      => \@units,
        title      => "Units",
    );
}

sub base : Chained('/project/base') PathPart('unit') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( unit => $c->project->units->find($id) || $c->detach('/error/not_found') );
}

sub edit : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $unit = $c->stash->{unit};

    my @articles = $unit->articles->sorted->hri->all;

    for my $article (@articles) {
        $article->{url} = $c->project_uri( '/article/edit', $article->{id} );
    }

    $c->stash(
        articles   => \@articles,
        update_url => $c->project_uri( $self->action_for('update'), $unit->id ),
    );

    $c->escape_title( Unit => $unit->long_name );
}

sub create : POST Chained('/project/base') PathPart('units/create') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->stash( unit => $c->project->new_related( units => {} ) );
    $c->detach('update_or_insert');
}

sub update : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->detach('update_or_insert');
}

sub update_or_insert : Private {
    my ( $self, $c ) = @_;

    my $unit = $c->stash->{unit};

    $unit->set_columns(
        {
            short_name => $c->req->params->get('short_name'),
            long_name  => $c->req->params->get('long_name'),
            space      => $c->req->params->get('space') ? '1' : '0',
        }
    );

    my @errors;

    if ( not $unit->in_storage ) {    # about to be created
        my $quantity = $c->req->params->get('quantity');

        if ( $c->project->quantities->exists( { id => $quantity } ) ) {
            $unit->set_column( quantity => $quantity );
        }
        else {
            push @errors, "Invalid quantity selected!";
        }
    }

    if ( $unit->in_storage and $unit->is_quantity_default ) {
        $unit->set_column( to_quantity_default => 1 );
    }
    else {
        $unit->set_column( to_quantity_default => $c->req->params->get('to_quantity_default') );

        ( $unit->to_quantity_default eq '' or looks_like_number( $unit->to_quantity_default ) )
          or push @errors, "Factor to quantity's default unit must be empty or a valid number!";
    }

    length $unit->short_name
      or push @errors, "Short name must be set!";

    if ( length $unit->long_name ) {
        my $is_unique = not $c->project->units->exists(
            { ( $unit->in_storage ? ( id => { '!=' => $unit->id } ) : () ), long_name => $unit->long_name } );

        $is_unique or push @errors, "Another unit with that long name already exists!";
    }
    else {
        push @errors, "Long name must be set!";
    }

    # TODO keep input values
    @errors and $c->redirect_detach(
        $c->project_uri(
            (
                $unit->in_storage
                ? ( $self->action_for('edit'), $unit->id )
                : $self->action_for('index')
            ),
            { error => "@errors" }
        )
    );

    $unit->update_or_insert();

    $c->detach('redirect');
}

sub delete : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->stash->{unit}->delete();
    $c->detach('redirect');
}

sub make_quantity_default : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->stash->{unit}->make_quantity_default();
    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->project_uri( $self->action_for('index') ) );
}

__PACKAGE__->meta->make_immutable;

1;
