package Coocook::Controller::Project::Quantity;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Project::Quantity - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : GET HEAD Chained('/project/unit/submenu') PathPart('quantities') Args(0)
  RequiresCapability('view_project') {
    my ( $self, $c ) = @_;

    my @quantities;

    {
        my $quantities = $c->project->quantities;
        $quantities = $quantities->sorted->search(
            undef,
            {
                prefetch   => 'default_unit',
                '+columns' => {
                    units_count => $quantities->correlate('units')->count_rs->as_query,
                },
            }
        );

        while ( my $quantity = $quantities->next ) {
            push @quantities,
              {
                name         => $quantity->name,
                default_unit => $quantity->default_unit,
                update_url   => $c->project_uri( $self->action_for('update'), $quantity->id ),
                delete_url   => $quantity->get_column('units_count') > 0
                ? undef
                : $c->project_uri( $self->action_for('delete'), $quantity->id ),
              };
        }
    }

    $c->stash(
        quantities => \@quantities,
        create_url => $c->project_uri( $self->action_for('create') ),
    );
}

sub create : POST Chained('/project/base') PathPart('quantities/create') Args(0)
  RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    my $name       = $c->req->params->get('name');
    my $quantities = $c->project->search_related('quantities');

    if ( $quantities->search( { name => $name } )->results_exist ) {
        $c->messages->error("A quantity with that name already exists");

        $c->stash( last_input => { name => $name } );

        $c->go( 'index', [ $c->project->id, $c->project->url_name ], [] );
    }

    $c->project->create_related( quantities => { name => $name } );
    $c->detach('redirect');
}

sub base : Chained('/project/base') PathPart('quantities') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( quantity => $c->project->quantities->find($id) || $c->detach('/error/not_found') );
}

sub delete : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->stash->{quantity}->delete();
    $c->detach('redirect');
}

sub update : POST Chained('base') Args(0) RequiresCapability('edit_project') {
    my ( $self, $c ) = @_;

    $c->stash->{quantity}->update(
        {
            name => $c->req->params->get('name'),
        }
    );
    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->project_uri( $self->action_for('index') ) );
}

__PACKAGE__->meta->make_immutable;

1;
