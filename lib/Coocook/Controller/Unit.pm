package Coocook::Controller::Unit;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use Scalar::Util qw(looks_like_number);

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

Coocook::Controller::Unit - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Chained('/project/base') PathPart('units') Args(0) {
    my ( $self, $c ) = @_;

    my @quantities =
      $c->project->quantities->sorted->search( undef, { prefetch => 'default_unit' } )->all;
    my %quantities = map { $_->id => $_ } @quantities;

    my %units_in_use;

    {
        my @resultsets = (
            $c->project->units->articles_units,    #perltidy
            $c->project->purchase_lists->items,
            $c->project->dishes->ingredients,
            $c->project->recipes->ingredients,
        );

        for my $resultset (@resultsets) {
            my $ids = $resultset->get_column( { distinct => 'unit' } );

            @units_in_use{ $ids->all } = ();       # set all keys to undef
        }
    }

    my @units;

    {
        my $action = $self->action_for('delete');

        my $units = $c->project->units->search( undef,
            { join => 'quantity', order_by => [ 'quantity.name', 'long_name' ] } );

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

            push @units, \%unit;

            next if exists $units_in_use{ $unit->{id} };

            if ( $unit->is_quantity_default ) {
                next if $unit->convertible_into > 0;
            }

            $unit{delete_url} = $c->project_uri( $action, $unit{id} );
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

    $c->stash( unit => $c->project->units->find($id) );    # TODO error handling

}

sub edit : GET Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $unit = $c->stash->{unit};

    $c->stash( articles => [ $unit->articles->sorted->all ] );

    $c->escape_title( Unit => $unit->long_name );
}

sub create : POST Chained('/project/base') PathPart('units/create') Args(0) {
    my ( $self, $c ) = @_;

    my $short_name          = scalar $c->req->param('short_name');
    my $long_name           = scalar $c->req->param('long_name');
    my $to_quantity_default = scalar $c->req->param('to_quantity_default');
    my $input_okay          = $self->check_input(
        $c,
        {
            short_name          => $short_name,
            long_name           => $long_name,
            to_quantity_default => $to_quantity_default,
            current_page        => '/units'
        }
    );
    if ($input_okay) {
        my $unit = $c->project->create_related(
            units => {
                short_name          => $short_name,
                long_name           => $long_name,
                quantity            => scalar $c->req->param('quantity') || undef,
                to_quantity_default => $to_quantity_default || undef,
                space               => scalar $c->req->param('space') ? '1' : '0',
            }
        );
        $c->detach( 'redirect', [$unit] );
    }

}

sub delete : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{unit}->delete();

    $c->detach('redirect');
}

sub make_quantity_default : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{unit}->make_quantity_default();

    $c->detach('redirect');
}

sub update : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $unit = $c->stash->{unit};

    my $short_name          = scalar $c->req->param('short_name');
    my $long_name           = scalar $c->req->param('long_name');
    my $to_quantity_default = scalar $c->req->param('to_quantity_default');
    my $input_okay          = $self->check_input(
        $c,
        {
            short_name          => $short_name,
            long_name           => $long_name,
            to_quantity_default => $to_quantity_default,
            current_page        => "/unit/" . $unit->id,
        }
    );
    if ($input_okay) {
        $unit->update(
            {
                short_name          => $short_name,
                long_name           => $long_name,
                to_quantity_default => $to_quantity_default || undef,
                space               => scalar $c->req->param('space') ? '1' : '0',
            }
        );
        $c->detach( 'redirect', [$unit] );
    }
}

sub redirect : Private {
    my ( $self, $c, $unit ) = @_;

    $c->response->redirect(
        $c->project_uri(
            $unit
            ? ( $self->action_for('edit'), $unit->id )
            : $self->action_for('index')
        )
    );
}

#check input of unit when creating and updating a unit
sub check_input : Private {
    my ( $self, $c, $args ) = @_;
    my $shortname           = $args->{short_name};
    my $longname            = $args->{long_name};
    my $to_quantity_default = $args->{to_quantity_default};
    my $current_page        = $args->{current_page};
    my $result              = 0;
    if ( length($shortname) <= 0 ) {
        $c->response->redirect(
            $c->uri_for( $current_page, { error => "Cannot create unit with empty short name!" } ) );
    }
    elsif ( length($longname) <= 0 ) {
        $c->response->redirect(
            $c->uri_for( $current_page, { error => "Cannot create unit with empty long name!" } ) );
    }
    elsif ( !( looks_like_number($to_quantity_default) ) ) {
        $c->response->redirect(
            $c->uri_for(
                $current_page,
                { error => "Please supply a valid number in 'Factor to quantity's default unit'.\n E.g.: 1.33" }
            )
        );
    }
    else {
        $result = 1;
    }
    return $result;
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
