package Coocook::Controller::Admin;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub base : Chained('/base') PathPart('admin') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        submenu_items => [
            { action => 'admin/faq/index',   text => "FAQ" },
            { action => 'admin/projects',    text => "Projects" },
            { action => 'admin/terms/index', text => "Terms" },
            { action => 'admin/users',       text => "Users" },
        ]
    );
}

sub index : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('admin_view') { }

sub projects : GET HEAD Chained('base') Args(0) RequiresCapability('admin_view') {
    my ( $self, $c ) = @_;

    # we expect every users to have >=1 projects
    # so better not preload 1:n relationship 'users'
    my @projects = $c->model('DB::Project')->sorted->hri->all;

    my %users = map { $_->{id} => $_ } $c->model('DB::User')->with_projects_count->hri->all;

    for my $project (@projects) {
        $project->{owner} = $users{ $project->{owner} } || die;
        $project->{url}   = $c->uri_for_action( '/project/show', [ $project->{url_name} ] );
    }

    for my $user ( values %users ) {
        $user->{url} = $c->uri_for_action( '/user/show', [ $user->{name} ] );
    }

    $c->stash( projects => \@projects );
}

sub users : GET HEAD Chained('base') Args(0) RequiresCapability('admin_view') {
    my ( $self, $c ) = @_;

    my $users = $c->model('DB::User')->with_projects_count->search( undef, { order_by => 'name' } );
    my @users = $users->hri->all;

    for my $user (@users) {
        $user->{url} = $c->uri_for_action( '/user/show', [ $user->{name} ] );
        $user->{update_url} = $c->uri_for( $self->action_for('update_user'), [ $user->{id} ] );

        if ( my $token_expires = $user->{token_expires} ) {
            if ( DateTime->now <= $users->parse_datetime($token_expires) ) {
                $user->{status} = sprintf "user requested password recovery link (valid until %s)", $token_expires;
            }
        }
        elsif ( $user->{token_hash} ) {
            $user->{status} = "user needs to verify e-mail address with verification link";
        }

        $user->{status} ||= "ok";
    }

    $c->stash( users => \@users );
}

sub user_base : Chained('base') PathPart('user') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash(
        user_object    # don't overwrite $user!
          => $c->model('DB::User')->find($id) || $c->detach('/error/not_found')
    );
}

sub update_user : POST Chained('user_base') PathPart('update') Args(0)
  RequiresCapability('manage_users') {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user_object};

    if ( defined( my $comment = $c->req->params->get('admin_comment') ) ) {
        $user->set_column( admin_comment => $comment );
    }

    $user->update();

    $c->redirect_detach( $c->uri_for( $self->action_for('users') ) );
}

__PACKAGE__->meta->make_immutable;

1;
