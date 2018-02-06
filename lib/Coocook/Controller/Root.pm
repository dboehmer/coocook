package Coocook::Controller::Root;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

# BEGIN-block necessary to make method attributes work
BEGIN { extends 'Coocook::Controller' }

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in Coocook.pm
__PACKAGE__->config( namespace => '' );

=head1 METHODS

=head2 index

The root page (/)

=cut

sub base : Chained('/') PathPart('') CaptureArgs(0) Does('RequireSSL') { }

sub begin : Private {
    my ( $self, $c ) = @_;

    $c->stash( user => $c->user );
}

sub auto : Private {
    my ( $self, $c ) = @_;

    # TODO distinguish GET and POST requests
    # is some of this information useful for POST controller code, too?

    if ( $c->action ne 'user/register' and $c->action ne 'user/post_register' ) {    # don't loop
        if ( !$c->user and !$c->model('DB::User')->exists ) {
            my $message = "There are currently no users registered at this Coocook installation."
              . " The first user you register will be site admin!";

            $c->redirect_detach( $c->uri_for_action( '/user/register', { error => $message } ) );
        }
    }

    $c->stash(
        map { $_ => $c->config->{$_} }
          qw<
          date_format_short
          date_format_long
          icon_type
          icon_url
          >
    );

    $c->stash(
        css => ['css/style.css'],
        js  => [
            'lib/jquery-3.2.1' .  ( $c->debug ? '.js' : '.min.js' ),
            'lib/marked/marked' . ( $c->debug ? '.js' : '.min.js' ),
            'js/script.js',
        ],
    );

    for my $key (qw< css js >) {
        if ( my $config = $c->config->{$key} ) {
            push @{ $c->stash->{$key} }, ref $config eq 'ARRAY' ? @$config : $config;
        }
    }

    # wrapper might be undef, e.g. after /email/begin
    exists $c->stash->{wrapper}
      or $c->stash( wrapper => 'wrapper.tt' );

    if ( not defined $c->stash->{errors} ) {
        $c->stash( errors => [ $c->req->query_params->get_all('error') ] );
    }

    if ( my $about = $c->config->{about_page_title} ) {
        $c->stash( about_title => $about );
    }

    $c->stash(
        homepage_url   => $c->uri_for_action('/index'),
        statistics_url => $c->uri_for_action('/statistics'),
        about_url      => $c->uri_for_action('/about'),
    );

    if ( $c->user ) {
        $c->stash(
            dashboard_url => $c->stash->{homepage_url},
            settings_url  => $c->uri_for_action('/settings'),
            logout_url    => $c->forward('/logout_url'),
        );
    }
    else {
        $c->stash( login_url => $c->forward('/login_url') );

        $c->user_registration_enabled
          and $c->stash( register_url => $c->uri_for_action('/user/register') );
    }

    if ( $c->has_capability('admin_view') ) {
        $c->stash( admin_url => $c->uri_for_action('/admin') );
    }

    return 1;    # important
}

sub index : GET HEAD Chained('/base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->go( $c->has_capability('dashboard') ? 'dashboard' : 'homepage' );
}

sub homepage : Private {
    my ( $self, $c ) = @_;

    $c->stash(
        meta_description => $c->config->{homepage_meta_description},
        meta_keywords    => $c->config->{homepage_meta_keywords},
        public_projects  => [ $c->model('DB::Project')->public->all ],
    );
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
        my_projects                => [ $my_projects->all ],
        other_projects             => [ $other_projects->all ],
        project_create_url         => $c->uri_for_action('/project/create'),
        can_create_private_project => $c->has_capability('create_private_project'),
    );
}

sub statistics : GET HEAD Chained('/base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        title      => "Statistics",
        statistics => $c->model('DB')->statistics,
    );
}

sub about : GET HEAD Chained('/base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        title => $c->config->{about_page_title} || "About",
        about_page_md => $c->config->{about_page_md},
    );
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
