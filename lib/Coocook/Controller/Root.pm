package Coocook::Controller::Root;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

=encoding utf-8

=head1 NAME

Coocook::Controller::Root - Root Controller for Coocook

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub begin : Private {
    my ( $self, $c ) = @_;

    $c->stash( user => $c->user );
}

sub auto : Private {
    my ( $self, $c ) = @_;

    # TODO distinguish GET and POST requests
    # is some of this information useful for POST controller code, too?

    $c->stash( map { $_ => $c->config->{$_} } qw< date_format_short date_format_long > );

    $c->stash(
        css => ['css/style.css'],
        js  => [
            'lib/jquery-3.2.1' .  ( $ENV{CATALYST_DEBUG} ? '.js' : '.min.js' ),
            'lib/marked/marked' . ( $ENV{CATALYST_DEBUG} ? '.js' : '.min.js' ),
            'js/script.js',
        ],
    );

    my $errors = $c->req->query_params->{error};
    if ( defined $errors ) {
        ref $errors or $errors = [$errors];
    }
    $c->stash( errors => $errors );

    $c->stash( homepage_url => $c->uri_for_action('/index') );

    if ( $c->user ) {
        $c->stash(
            dashboard_url => $c->stash->{homepage_url},
            logout_url    => $c->uri_for_action('/logout'),
        );
    }
    else {
        $c->stash(
            login_url    => $c->uri_for_action('/login'),
            register_url => $c->uri_for_action('/user/register'),
        );
    }
}

sub index : GET Path Args(0) {
    my ( $self, $c ) = @_;

    $c->go( $c->user ? 'dashboard' : 'homepage' );
}

sub homepage : Private {
    my ( $self, $c ) = @_;

    $c->stash( projects => [ $c->model('DB::Project')->all ] );
}

sub dashboard : Private {
    my ( $self, $c ) = @_;

    $c->stash(
        project_create_url => $c->uri_for_action('/project/create'),
        projects           => [ $c->model('DB::Project')->all ],
    );
}

=head2 default

Standard 404 error page

=cut

sub default : Path {
    my ( $self, $c ) = @_;
    $c->response->body('Page not found');
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;

    for ( @{ $c->stash->{css} }, @{ $c->stash->{js} } ) {
        $_ = $c->uri_for( '/static/' . $_ );
    }
}

__PACKAGE__->meta->make_immutable;

1;
