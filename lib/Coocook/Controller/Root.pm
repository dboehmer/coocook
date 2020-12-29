package Coocook::Controller::Root;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use HTML::Meta::Robots;

# BEGIN-block necessary to make method attributes work
BEGIN { extends 'Coocook::Controller' }

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in Coocook.pm
__PACKAGE__->config( namespace => '' );

=head1 METHODS

=head2 index

The root page (/)

=cut

sub base : Chained('/') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    if ( not $c->req->secure ) {
        if ( $c->debug ) {
            $c->log->warn("Not redirecting to HTTPS in debug mode");
        }
        elsif ( $c->req->uri->port == 3000 and $c->req->uri->host eq 'localhost' ) {
            $c->log->warn("Not redirecting to HTTPS on development port localhost:3000");
        }
        else {
            my $method = $c->req->method;

            if ( $method eq 'GET' or $method eq 'HEAD' ) {
                my $uri = $c->req->uri->clone;
                $uri->scheme('https');
                $c->redirect_detach( $uri, 301 );
            }
            else {
                # TODO is this the best to do?
                $c->detach( '/error/bad_request',
                    ["Sending $method data through HTTP without encryption is not allowed."] );
            }
        }
    }
}

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

    $c->stash->{messages} = $c->session->{messages} ||= $c->model('Messages')->new;

    # set these stash vars before any possible redirect_detach() calls
    $c->stash( robots => my $robots = HTML::Meta::Robots->new() );

    if ( $c->action ne 'user/register' and $c->action ne 'user/post_register' ) {    # don't loop
        if ( !$c->user and !$c->model('DB::User')->results_exist ) {
            $c->redirect_detach( $c->uri_for_action('/user/register') );
        }
    }

    $c->stash(
        map { $_ => $c->config->{$_} }
          qw<
          date_format_short
          date_format_long
          help_links
          icon_type
          icon_url
          icon_urls
          >
    );

    $c->stash(
        css => [
            '/lib/bootstrap-4.4.1-dist/css/bootstrap' . ( $c->debug ? '.css' : '.min.css' ),
            '/css/local_bootstrap_modifications.css',
            '/css/material-design-icons.css',
            '/css/style.css',
        ],
        js => [
            '/lib/jquery-3.5.1' .                      ( $c->debug ? '.js' : '.min.js' ),
            '/lib/bootstrap-4.4.1-dist/js/bootstrap' . ( $c->debug ? '.js' : '.min.js' ),
            '/lib/marked/marked' .                     ( $c->debug ? '.js' : '.min.js' ),
            '/js/script.js',
        ],
    );

    for my $key (qw< css js >) {
        if ( my $config = $c->config->{$key} ) {
            push @{ $c->stash->{$key} }, ref $config eq 'ARRAY' ? @$config : $config;
        }
    }

    if ( my $about = $c->config->{about_page_title} ) {
        $c->stash( about_title => $about );
    }

    $c->stash(
        homepage_url   => $c->uri_for_action('/index'),
        recipes_url    => $c->uri_for_action('/browse/recipe/index'),
        projects_url   => $c->uri_for_action('/browse/project/index'),
        statistics_url => $c->uri_for_action('/statistics'),
        about_url      => $c->uri_for_action('/about'),
    );

    if ( my $base = $c->config->{canonical_url_base} ) {
        my $rel_path = '.' . $c->current_uri_local_part;
        my $uri      = URI->new_abs( $rel_path, $base );
        $uri->query(undef);

        $c->stash( canonical_url => $uri );
    }

    if ( $c->model('DB::FAQ')->results_exist ) {
        $c->stash( faq_url => $c->uri_for_action('/faq/index') );
    }

    if ( $c->user ) {
        $robots->index(0);

        $c->stash(
            dashboard_url => $c->stash->{homepage_url},
            settings_url  => $c->uri_for_action('/settings/index'),
            logout_url    => $c->redirect_uri_for_action('/session/logout'),
        );
    }
    else {
        $c->stash(    # login/register URLs with previous application path as query parameter
            login_url    => $c->redirect_uri_for_action('/session/login'),
            register_url => $c->user_registration_enabled
            ? $c->redirect_uri_for_action('/user/register')
            : undef,
        );
    }

    $c->stash(
        admin_url  => $c->uri_for_action_if_permitted('/admin/index'),
        admin_urls => {    # TODO list duplicates code in Controller::Admin
            faq           => $c->uri_for_action_if_permitted('/admin/faq/index'),
            organizations => $c->uri_for_action_if_permitted('/admin/organizations'),
            projects      => $c->uri_for_action_if_permitted('/admin/projects'),
            terms         => $c->uri_for_action_if_permitted('/admin/terms/index'),
            users         => $c->uri_for_action_if_permitted('/admin/user/index'),
        },
    );

    # has current terms or has any terms (valid in future then)
    if ( $c->model('DB::Terms')->results_exist ) {
        $c->stash( terms_url => $c->uri_for_action('/terms/index') );
    }

    return 1;    # important
}

sub index : GET HEAD Chained('/base') PathPart('') Args(0) Public {
    my ( $self, $c ) = @_;

    $c->detach( $c->has_capability('view_dashboard') ? 'dashboard' : 'homepage' );
}

sub homepage : Private {
    my ( $self, $c ) = @_;

    my $max_recipes = 10;

    my @public_recipes = $c->model('DB::Recipe')->public->search(
        undef,
        {
            join     => 'project',
            order_by => { -desc => 'project.created' },
            rows     => $max_recipes,
        }
    )->all;

    for (@public_recipes) {
        $_ = $_->as_hashref( url => $c->uri_for_action( '/browse/recipe/show', [ $_->id, $_->url_name ] ) );
    }

    my @active_public_projects = $c->model('DB::Project')->not_archived->public->sorted->hri->all;

    for my $project (@active_public_projects) {
        $project->{url} = $c->uri_for_action( '/project/show', [ $project->{id}, $project->{url_name} ] );
    }

    $c->stash(
        meta_description       => $c->config->{homepage_meta_description},
        meta_keywords          => $c->config->{homepage_meta_keywords},
        max_recipes            => $max_recipes,
        public_recipes         => \@public_recipes,
        active_public_projects => \@active_public_projects,
        template               => 'homepage.tt',
    );
}

sub dashboard : Private {
    my ( $self, $c ) = @_;

    my $my_projects = $c->user->projects->union(
        $c->user->organizations->search_related('organizations_projects')->search_related('project') )
      ->not_archived;

    my @my_projects = $my_projects->sorted->hri->all;

    my $other_projects = $c->model('DB::Project')->not_archived->public;

    if ( @my_projects > 0 ) {
        $other_projects =  # TODO for users with extremely many projects the SQL statement will be too large
          $other_projects->search( { id => { -not_in => [ map { $_->{id} } @my_projects ] } } );
    }

    my @other_projects = $other_projects->sorted->hri->all;

    for my $project ( @my_projects, @other_projects ) {
        $project->{url} = $c->uri_for_action( '/project/show', [ $project->{id}, $project->{url_name} ] );
    }

    $c->stash(
        my_projects                => \@my_projects,
        other_projects             => \@other_projects,
        all_my_projects_url        => $c->uri_for_action('/settings/projects'),
        project_create_url         => $c->uri_for_action('/project/create'),
        can_create_private_project => !!$c->has_capability('create_private_project'),
        template                   => 'dashboard.tt',
    );
}

sub statistics : GET HEAD Chained('/base') Args(0) Public {
    my ( $self, $c ) = @_;

    $c->stash( statistics => $c->model('DB')->statistics );
}

sub about : GET HEAD Chained('/base') Args(0) Public {
    my ( $self, $c ) = @_;

    # configured globally (instead of in TT) for menu item
    $c->stash( title => $c->config->{about_page_title} );
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
            if ( $action =~ m/ ^ (admin|settings) \/ /x ) {    # TODO how to distinguish this in a generic way?
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

    {
        my $errors = $c->stash->{errors};
        my $status = $c->res->status;

        if ( ref $errors eq 'ARRAY' ? @$errors > 0 : $errors or $status =~ m/^[45]..$/ ) {
            $c->stash->{robots}->archive(0);
            $c->stash->{robots}->index(0);
        }
    }

    $c->stash( meta_robots => $c->stash->{robots}->content );
}

=head2 _validated_redirect

Gets a redirect URL from the current request URI's query parameter C<redirect>
and validates the URL path. If the paramter is present and the URL is valid,
the client is redirected to this URL.

In every other case the client is redirected to C</>.

=cut

sub _validated_redirect : Private {
    my ( $self, $c ) = @_;

    my $uri;

  URI: for (1) {    # to exit easily with `last`
        my $path = $c->req->params->get('redirect')
          or last;

        my @regexes = (    # TODO is this sufficient to assert security?
            qr!\.\.!,       # path traversal
            qr!^//!,        # same protocol URI
            qr!^\w+://!,    # explicit protocol URI
        );

        for my $regex (@regexes) {
            $path =~ $regex
              and last URI;
        }

        $path =~ s! ^/ !!x    # paths must be absolute to app root
          or last;

        $uri = $c->uri_for_local_part($path);
    }

    # don't $c->detach() here, caller can decide between visit() or detach()
    $c->response->redirect( $uri || $c->uri_for('/') );
}

__PACKAGE__->meta->make_immutable;

1;
