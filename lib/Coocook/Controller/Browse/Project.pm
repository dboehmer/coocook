package Coocook::Controller::Browse::Project;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Browse::Project - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub index : GET HEAD Chained('/base') PathPart('projects') Args(0) Public {
    my ( $self, $c ) = @_;

    my $projects = $c->model('DB::Project')->public;

    if ( my $user = $c->user ) {
        $projects = $projects->union(

            # without search() exception:
            # Can't locate object method "_resolved_attrs" via package "Coocook::Model::DB::Project"
            $user->projects->search()
        );
    }

    my @projects = $projects->sorted->hri->all;

    for my $project (@projects) {
        $project->{url} = $c->uri_for_action( '/project/show', [ $project->{id}, $project->{url_name} ] );
    }

    $c->stash( projects => \@projects );
}

__PACKAGE__->meta->make_immutable;

1;
