package Coocook::Controller::Admin;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

__PACKAGE__->config( namespace => '' );

sub admin_base : Chained('/base') PathPart('admin') CaptureArgs(0) { }

sub admin : GET HEAD Chained('admin_base') PathPart('') Args(0) RequiresCapability('admin_view') {
    my ( $self, $c ) = @_;

    my @projects = $c->model('DB::Project')->sorted->hri->all;

    my $users = $c->model('DB::User');
    my @users = $users->search(
        undef,
        {
            order_by   => 'display_name',
            '+columns' => {
                projects_count => $users->correlate('owned_projects')->count_rs->as_query
            },
        }
    )->hri->all;

    my %users = map { $_->{id} => $_ } @users;

    for my $project (@projects) {
        $project->{owner} = $users{ $project->{owner} };
        $project->{url} = $c->uri_for_action( '/project/edit', [ $project->{url_name} ] );
    }

    for my $user (@users) {
        $user->{url} = $c->uri_for_action( '/user/show', [ $user->{name} ] );
    }

    $c->stash(
        projects => \@projects,
        users    => \@users,
        title    => "Admin",
    );
}

__PACKAGE__->meta->make_immutable;

1;