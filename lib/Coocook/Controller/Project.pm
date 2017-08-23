package Coocook::Controller::Project;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Project - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

# override begin() in Controller::Root
sub begin : Private { }

sub edit : Path : Args(1) {
    my ( $self, $c, $id ) = @_;
    my $project = $c->model('DB::Project')->find($id);

    my $default_date = DateTime->today;

    my $days = do {
        my %days;

        my $meals = $project->meals->search( undef, { prefetch => 'dishes' } );

        # group meals by date
        while ( my $meal = $meals->next ) {
            $default_date < $meal->date and $default_date = $meal->date;

            push @{ $days{ $meal->date }{meals} }, $meal;
        }

        for my $day ( values %days ) {
            $day->{dishes} = 0;
            $day->{dishes} += $_->dishes->count for @{ $day->{meals} };

            # save DateTime object for table display
            $day->{date} = $day->{meals}[0]->date;
        }

        # remove sort keys, save sorted list
        [ map { $days{$_} } sort keys %days ];
    };

    $c->stash(
        default_date => $default_date,
        project      => $project,
        recipes      => [ $c->model('DB::Recipe')->search( undef, { order_by => 'name' } )->all ],
        days         => $days,
    );
}

sub edit_dishes : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;

    my $project = $c->model('DB::Project')->find($id);

    my @dish_ids = grep { $c->req->param("dish$_") } $project->meals->dishes->get_column('id')->all;

    my $dishes = $c->model('DB::Dish')->search( { id => { -in => \@dish_ids } } );

    if ( $c->req->param('update') ) {
        if ( $c->req->param('edit_comment') ) {
            $dishes->update( { comment => scalar $c->req->param('new_comment') } );
        }

        if ( $c->req->param('edit_servings') ) {
            for my $dish ( $dishes->all ) {
                $dish->recalculate( scalar $c->req->param('new_servings') );
            }
        }
    }
    elsif ( $c->req->param('delete') ) {
        while ( my $dish = $dishes->next ) {    # fetch objects for cascade delete of ingredients
            $dish->delete();
        }
    }

    $c->detach( redirect => [ $project->id ] );
}

sub create : Local : POST {
    my ( $self, $c, $id ) = @_;
    my $name = $c->req->param('name');
    if ( length($name) > 0 ) {
        my $project = $c->model('DB::Project')->create( { name => scalar $c->req->param('name') } );
        $c->detach( 'redirect', [ $project->id ] );
    }
    else {
        $c->response->redirect(
            $c->uri_for( '/projects', { error => "Cannot create project with empty name!" } ) );
    }
}

sub rename : Local POST {
    my ( $self, $c, $id ) = @_;

    my $name = $c->req->param('name');

    my $project = $c->model('DB::Project')->find($id);

    $project->update( { name => $name } );

    $c->detach( redirect => [ $project->id ] );
}

sub select : Local Args(1) GET {
    my ( $self, $c, $id ) = @_;
    my $project = $c->model('DB::Project')->find($id);
    $c->session->{project} = $project->id;
    $c->response->redirect('/');
}

sub redirect : Private {
    my ( $self, $c, $id ) = @_;
    $c->response->redirect( $c->uri_for_action( $self->action_for('edit'), $id ) );
}

#TODO: enable deletion of big projects?
sub delete : Local Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('DB::Project')->find($id)->delete;
    $c->response->redirect('/projects');
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
