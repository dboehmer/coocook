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

sub enforce_ssl : Chained('/') PathPart('') CaptureArgs(0) Does('RequireSSL') { }

sub begin : Private {
    my ( $self, $c ) = @_;

    $c->stash( user => $c->user );
}

sub auto : Private {
    my ( $self, $c ) = @_;

    # TODO distinguish GET and POST requests
    # is some of this information useful for POST controller code, too?

    if ( $c->action ne 'user/register' and $c->action ne 'user/post_register' ) {    # don't loop
        if ( !$c->user and $c->model('DB::User')->count == 0 ) {
            my $message = "There are currently no users registered at this Coocook installation."
              . " The first user you register will be global admin!";

            $c->response->redirect( $c->uri_for_action( '/user/register', { error => $message } ) );
            $c->detach;
        }
    }

    $c->stash( map { $_ => $c->config->{$_} } qw< date_format_short date_format_long > );

    $c->stash(
        css => ['css/style.css'],
        js  => [
            'lib/jquery-3.2.1' .  ( $ENV{CATALYST_DEBUG} ? '.js' : '.min.js' ),
            'lib/marked/marked' . ( $ENV{CATALYST_DEBUG} ? '.js' : '.min.js' ),
            'js/script.js',
        ],
    );

    # wrapper might be undef, e.g. after /email/begin
    exists $c->stash->{wrapper}
      or $c->stash( wrapper => 'wrapper.tt' );

    if ( not defined $c->stash->{errors} ) {
        my $errors = $c->req->query_params->{error} || [];

        ref $errors eq 'ARRAY'
          or $errors = [$errors];

        $c->stash( errors => $errors );
    }

    $c->stash(
        homepage_url   => $c->uri_for_action('/index'),
        statistics_url => $c->uri_for_action('/statistics'),
    );

    if ( $c->user ) {
        $c->stash(
            dashboard_url => $c->stash->{homepage_url},
            settings_url  => $c->uri_for_action('/settings'),
            logout_url    => $c->uri_for_action('/logout'),
        );
    }
    else {
        $c->stash(
            login_url    => $c->uri_for_action('/login'),
            register_url => $c->uri_for_action('/user/register'),
        );
    }

    return 1;    # important
}

sub index : GET Chained('/enforce_ssl') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->go( $c->user ? 'dashboard' : 'homepage' );
}

sub homepage : Private {
    my ( $self, $c ) = @_;

    $c->stash( public_projects => [ $c->model('DB::Project')->public->all ] );
}

sub dashboard : Private {
    my ( $self, $c ) = @_;

    my $my_projects = $c->user->projects;

    my $other_projects = $c->model('DB::Project')->public->search(
        {
            id => { -not_in => $my_projects->get_column('id')->as_query },
        }
    );

    $c->stash(
        my_projects        => [ $my_projects->all ],
        other_projects     => [ $other_projects->all ],
        project_create_url => $c->uri_for_action('/project/create'),
    );
}

sub statistics : GET Chained('/enforce_ssl') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        title      => "Statistics",
        statistics => $c->model('DB')->statistics,
    );
}

=head2 default

Standard 404 error page

=cut

sub default : Chained('/enforce_ssl') {
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
