package Coocook::Controller::Project;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

Coocook::Controller::Project - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 base

Chain action that captures the project ID and stores the
C<Result::Project> object in the stash.

=cut

sub base : Chained('/') PathPart('project') CaptureArgs(1) {
    my ( $self, $c, $url_name ) = @_;

    if ( my $project = $c->model('DB::Project')->find_by_url_name($url_name) ) {
        if ( $c->req->method eq 'GET' and $url_name ne $project->url_name ) {

            # TODO redirect to same URL with $url_name in exact case
            # e.g. /project/fOO => /project/Foo (for url_name 'Foo' in database)
        }

        $c->stash( project => $project );
    }
    else {
        $c->response->redirect( $c->uri_for( '/', { error => "Project not found" } ) );
        $c->detach;
    }
}

=head2 index

=cut

sub edit : GET Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $default_date = DateTime->today;

    my $days = $c->model('Plan')->project( $c->project );

    # calculate dishes per day for table's row-span
    for my $day (@$days) {
        $day->{dishes} = 0;

        for my $meal ( @{ $day->{meals} } ) {
            my $dishes = @{ $meal->{dishes} };
            $day->{dishes} += $dishes;
            $meal->{deletable} = not $dishes;
        }
    }

    $c->stash(
        default_date          => $default_date,
        recipes               => [ $c->project->recipes->sorted->all ],
        days                  => $days,
        deletion_confirmation => $c->config->{project_deletion_confirmation},
    );
}

sub get_import : GET Chained('base') PathPart('import') Args(0) {   # import() already used by 'use'
    my ( $self, $c ) = @_;

    my @projects = $c->project->other_projects->all;

    my $importer = $c->model('Importer');

    $c->stash(
        projects        => \@projects,
        properties      => $importer->properties,
        properties_json => $importer->properties_json,
        import_url      => $c->project_uri('/project/post_import'),
        template        => 'project/import.tt',
    );
}

sub post_import : POST Chained('base') PathPart('import') Args(0) { # import() already used by 'use'
    my ( $self, $c ) = @_;

    my $importer = $c->model('Importer');
    my $source   = $c->model('DB::Project')->find( scalar $c->req->param('source_project') );
    my $target   = $c->project;

    # extract properties selected in form
    my @properties =
      grep { $c->req->param("property_$_") } map { $_->{key} } @{ $importer->properties };

    $importer->import_data( $source => $target, \@properties );

    $c->detach( redirect => [$target] );
}

sub edit_dishes : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $project = $c->project;

    # filter selected IDs from possible dish IDs
    my @dish_ids = grep { $c->req->param("dish$_") } $project->meals->dishes->get_column('id')->all;

    # select dishes from valid ID list
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

    $c->detach( redirect => [$project] );
}

sub create : POST Local {
    my ( $self, $c ) = @_;

    if ( length( my $name = $c->req->param('name') ) > 0 ) {
        my $project = $c->model('DB::Project')->new_result( {} );
        $project->name( scalar $c->req->param('name') );
        $project->insert;

        $c->response->redirect(
            $c->uri_for_action( $self->action_for('get_import'), [ $project->url_name ] ) );
    }
    else {
        $c->response->redirect( $c->uri_for( '/', { error => "Cannot create project with empty name!" } ) );
    }
}

sub rename : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    my $project = $c->stash->{project};

    $project->update( { name => scalar $c->req->param('name') } );

    $c->detach( redirect => [$project] );
}

sub delete : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    if ( $c->req->param('confirmation') eq $c->config->{project_deletion_confirmation} ) {
        $c->project->delete;
        $c->response->redirect( $c->uri_for_action('/index') );
    }
    else {
        $c->response->redirect( $c->project_uri('/project/edit') );
    }
}

sub redirect : Private {
    my ( $self, $c, $project ) = @_;

    $c->response->redirect( $c->uri_for_action( $self->action_for('edit'), [ $project->url_name ] ) );
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
