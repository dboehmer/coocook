package Coocook::Controller::Root;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

# version 1.0.0 changed HTTP status code for SSL redirects to 301
use Catalyst::ActionRole::RequireSSL v1.0.0;

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

    $c->stash(
        name     => $c->config->{name},
        user     => $c->user,
        user_url => $c->user ? $c->uri_for_action( '/user/show', [ $c->user->name ] ) : undef,
    );
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
          footer_html
          help_links
          icon_type
          icon_url
          >
    );

    $c->stash(
        css => ['/css/style.css'],
        js  => [
            '/lib/jquery-3.2.1' .  ( $c->debug ? '.js' : '.min.js' ),
            '/lib/marked/marked' . ( $c->debug ? '.js' : '.min.js' ),
            '/js/script.js',
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

    if ( $c->model('DB::FAQ')->exists ) {
        $c->stash( faq_url => $c->uri_for_action('/faq/index') );
    }

    if ( $c->user ) {
        $c->stash(
            dashboard_url => $c->stash->{homepage_url},
            settings_url  => $c->uri_for_action('/settings/index'),
            logout_url    => $c->forward('/logout_url'),
        );
    }
    else {
        # login URI with current application path as query parameter or current login URI itself
        $c->stash(
            login_url => $c->req->path =~ m{ ^ login /? $ }x ? $c->req->uri : $c->forward('/login_url') );

        $c->user_registration_enabled
          and $c->stash( register_url => $c->uri_for_action('/user/register') );
    }

    if ( $c->has_capability('admin_view') ) {
        $c->stash( admin_url => $c->uri_for_action('/admin/index') );
    }

    # has current terms or has any terms (valid in future then)
    if ( $c->model('DB::Terms')->exists ) {
        $c->stash( terms_url => $c->uri_for_action('/terms/index') );
    }

    return 1;    # important
}

sub index : GET HEAD Chained('/base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->go( $c->has_capability('dashboard') ? 'dashboard' : 'homepage' );
}

sub homepage : Private {
    my ( $self, $c ) = @_;

    my @public_projects = $c->model('DB::Project')->public->sorted->hri->all;

    for my $project (@public_projects) {
        $project->{url} = $c->uri_for_action( '/project/show', [ $project->{url_name} ] );
    }

    $c->stash(
        meta_description => $c->config->{homepage_meta_description},
        meta_keywords    => $c->config->{homepage_meta_keywords},
        homepage_text_md => $c->config->{homepage_text_md},
        public_projects  => \@public_projects,
    );
}

sub dashboard : Private {
    my ( $self, $c ) = @_;

    my $my_projects = $c->user->projects;

    my @my_projects = $my_projects->sorted->hri->all;

    my @other_projects = $c->model('DB::Project')->public->search(
        {
            id => { -not_in => $my_projects->get_column('id')->as_query },
        }
    )->sorted->hri->all;

    for my $project ( @my_projects, @other_projects ) {
        $project->{url} = $c->uri_for_action( '/project/show', [ $project->{url_name} ] );
    }

    $c->stash(
        my_projects                => \@my_projects,
        other_projects             => \@other_projects,
        project_create_url         => $c->uri_for_action('/project/create'),
        can_create_private_project => $c->has_capability('create_private_project'),
    );
}

sub statistics : GET HEAD Chained('/base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( statistics => $c->model('DB')->statistics );
}

sub about : GET HEAD Chained('/base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        title         => $c->config->{about_page_title},
        about_page_md => $c->config->{about_page_md},
    );
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;

    for my $item ( @{ $c->stash->{submenu_items} } ) {
        my $action = $item->{action};

        my $capabilities = $self->action_for($action)->attributes->{RequiresCapability};

        for my $capability (@$capabilities) {
            if ( not $c->has_capability($capability) ) {
                $item->{forbidden} = 1;
                next;
            }
        }

        if ( $c->action ne $action ) {
            if ( $action =~ m/ ^ admin /x ) {    # TODO how to distinguish this in a generic way?
                $item->{url} = $c->uri_for_action($action);
            }
            else {
                $item->{url} = $c->project_uri($action);
            }
        }
    }

    # remove subitems that have the 'forbidden' flag
    @{ $c->stash->{submenu_items} } = grep { not $_->{forbidden} } @{ $c->stash->{submenu_items} };

    for ( @{ $c->stash->{css} }, @{ $c->stash->{js} } ) {
        $_ = $c->uri_for_static($_);
    }
}

__PACKAGE__->meta->make_immutable;

1;
