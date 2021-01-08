package Coocook::Helpers;

# ABSTRACT: role with useful Controller helper methods as $c->my_helper(...)

use Carp;
use Moose::Role;
use MooseX::MarkAsMethods autoclean => 1;
use Scalar::Util qw< blessed >;

=head1 METHODS

=head2 $c->current_uri_local_part()

Returns the URI for the current request with only the app-local part
that can be passed to C<< $c->uri_for_local_part($uri_local_part) >>.

=cut

# TODO better name?
# TODO test this
sub current_uri_local_part {
    my ($c) = @_;

    my $current_uri = $c->req->uri->rel( $c->req->base );

    $current_uri =~ s! ^ \. / !/!x             # ./     => /
      or $current_uri = '/' . $current_uri;    # foobar => /foobar

    return $current_uri;
}

=head2 $c->uri_for_local_part($local_part)

Similar to C<< $c->uri_for() >> but accepts query part.

=cut

# TODO test this
sub uri_for_local_part {
    my ( $c, $local_part ) = @_;

    return $c->req->base . $local_part;
}

=head2 $c->uri_for(...)

Overrides L<< $c->uri_for()|Catalyst/"$c->uri_for( $path?, @args?, \%query_values?, \$fragment? )" >>
to raise an exception if the URI can't be generated.

=cut

around uri_for => sub {
    my $orig = shift;
    my $self = shift;

    my $uri = $self->$orig(@_);

    return $uri if $uri;

    local @Coocook::Helpers::CARP_NOT = 'Class::MOP::Method::Wrapped';
    croak 'Catalyst->uri_for() returned undef';
};

=head2 uri_for_action_if_permitted( $action, \%input?, @args? )

=head2 uri_for_action_if_permitted( $action, \%input, @args?, \%query_values )

Similar to C<< $c->uri_for >> but returns the URI only if the action
is permitted, i.e. not prohibited by RequiresCapability attributes.

If the 1st argument to C<uri_for_action> was a hashref, then another
hashref must be passed as C<$input> before. It might be empty C<{}>.

Returns C<undef> if action is not permitted.

    package Coocook::Controller::Foo;

    sub bar : RequiresCapability('view_bar') { ... }

    sub baz {
        my ( $self, $c ) = @_;

        # with path and query arguments
        my $uri = $c->uri_for_action_if_permitted( '/foo/bar', { limit => 42 } );

        # with action object and path parameter
        $c->stash(
            foo_bar_uri => $c->uri_for_action_if_permitted( $self->action_for('bar'), [ $id ] ),
            ...
        );
    }

=cut

sub uri_for_action_if_permitted {    # logic stolen from Catalyst->uri_for_action()
    my $c     = shift;
    my $path  = shift;
    my $input = @_ && ref $_[0] eq 'HASH' ? shift : undef;

    my $action = blessed($path) ? $path : $c->dispatcher->get_action_by_path($path);

    $action // croak "Can't find action for path '$path'";

    my $capabilities = $action->attributes->{RequiresCapability};

    $capabilities and @$capabilities > 0
      or croak "Action doesn't declare any required capabilities";

    for (@$capabilities) {
        $c->has_capability( $_, $input )
          or return (undef);    # needs 1 list element when used in $c->stash()
    }

    return $c->uri_for( $action, @_ );
}

=head2 $c->has_capability( $capability, \%input? )

Returns boolish value from L<Coocook::Model::Authorization> whether current
user has C<$capability> and collects necessary information from C<< $c->stash >> automatically.
C<\%input> may override information from stash.

    # most common case
    $c->has_capability('admin_view')

    # check capability on other project
    $c->has_capability('view_project', { project => $project_to_import_from } );

=cut

sub has_capability {
    my ( $c, $capability, $input ) = @_;

    my $authz = $c->model('Authorization');

    $input //= {};

    for my $key ( 'project', 'user', $authz->capability_needs_input($capability) ) {
        $input->{$key} //= $c->stash->{$key};
    }

    # TODO workaround for https://rt.cpan.org/Public/Bug/Display.html?id=97640
    # this wrapper around Result::User shall not silence exceptions
    for ( $input->{user} ) {
        ref eq 'Catalyst::Authentication::Store::DBIx::Class::User'
          and $_ = $_->get_object;
    }

    return $authz->has_capability( $capability, $input );
}

=head2 $c->require_capability( $capability, \%input? )

Checks authorization via L<Coocook::Model::Authorization>.
If not permitted might ask user to log in
or detaches to C</error/forbidden>.

This can be called in any controller code and is called automatically
if L<Coocook::ActionRole::RequiresCapability> is applied to an action.

=cut

sub require_capability {
    my $c = shift;

    $c->has_capability(@_)
      and return 1;

    # not logged in? try login and redirect here again
    if ( $c->req->method eq 'GET' and not $c->user ) {    # TODO also for HEAD?
        $c->redirect_detach( $c->redirect_uri_for_action('/session/login') );
    }

    $c->detach('/error/forbidden');
}

=head2 $c->messages

Returns the L<Coocook::Model::Messages> object for the current session.

    $c->messages->debug("add message");    # call methods on object
    my @messages = @{ $c->messages };     # use as arrayref

=cut

sub messages { return shift->stash->{messages} }

=head2 $c->project_uri($action, @arguments, \%query_params?)

Return URI for project-specific Catalyst action with the current project's C<id> and C<url_name>
plus any number of C<@arguments> and possibly C<\%query_params>.

    my $uri = $c->project_uri( '/article/edit', $article->id, { key => 'value' } );
    # http://localhost/project/MyProject/article/42?key=value

    my $uri = $c->project_uri( $self->action_for('edit'), $article->id, { key => 'value' } );
    # the same

=cut

sub project_uri {
    my $c      = shift;
    my $action = shift;

    my $project = $c->stash->{project}
      or croak "Missing 'project' in stash";

    # if last argument is hashref that's the \%query_values argument
    my @query = ref $_[-1] eq 'HASH' ? pop @_ : ();

    return $c->uri_for_action( $action, [ $project->id, $project->url_name, @_ ], @query );
}

sub project {
    my $c = shift;

    $c->stash->{project};
}

=head2 $c->redirect_canonical_case( $args_index, $canonical_value )

Check the value of path arguments at index C<$args_index>.
If the value has different case than C<$canonical_value>,
redirects to the same URL with the canonical value at index C<$args_index>.

Effective only for GET and HEAD requests. Does nothing for any other request.

    # given an object identified by 'Name':

    POST /my_action/nAmE  # ignored because POST
    GET  /my_action/nAmE  # redirects to:
    GET  /my_action/Name

For the redirect to be effective the current action needs to be public
or the capabilities required by the action must be given.

=cut

sub redirect_canonical_case {
    my ( $c, $args_index, $canonical_value ) = @_;

    $c->req->method eq 'GET'
      or $c->req->method eq 'HEAD'
      or return;

    my $url_value = $c->req->args->[$args_index];

    $url_value eq $canonical_value
      and return 1;

    # must not redirect to canonical value unless permitted,
    # e.g. /project/42 must not reveal name of private projects
    my $attrs = $c->action->attributes;

    if    ( exists $attrs->{Public} ) { }                          # always ok
    elsif ( my $capabilities = $attrs->{RequiresCapability} ) {    # check
        $c->has_capability( $_, $c->stash ) || return for @$capabilities;
    }
    else {                                                         # action can't be checked here
        return;
    }

    my @args = @{ $c->req->captures };    # $c->req->args contains only args for current chain element
    $args[$args_index] = $canonical_value;

    my $uri = $c->uri_for( $c->action, \@args );
    $uri->query( $c->req->uri->query );

    $c->redirect_detach( $uri, 301 );
}

=head2 $c->redirect_detach(@redirect_args)

Set HTTP C<Location:> header to redirect URI and detach from Catalyst request flow in 1 step.
Passes all arguments to C<< $c->response->redirect() >>. Method never returns.

=cut

sub redirect_detach {
    my $c = shift;

    $c->response->redirect(@_);
    $c->detach;
}

=head2 $c->redirect_uri_for_action( $action, @arguments, \%query_params )

Should support same method arguments as Catalyst's C<< $c->uri_for_action() >>
but adds a query parameter C<redirect> to the current page's path and query.
Except when the current URI contains a C<redirect> query parameter--then
its value is passed along.

=cut

sub redirect_uri_for_action {
    my $c = shift;

    # complex signature of Catalyst->uri_for_action()
    my $query = @_ >= 2 && ref $_[-1] eq 'HASH'
      ? $_[-1]                             # use existing hashref
      : do { push @_, my $q = {}; $q };    # push hashref to @_

    if ( my $redirect = $c->req->query_params->get('redirect') ) {
        ## TODO validate redirect
        $query->{redirect} = $redirect;
    }
    else {
        # URL built with current_uri_local_part() in POST request might be inaccessible via GET
        if ( $c->req->method eq 'GET' ) {    # TODO also HEAD?
            my $current_uri_local_part = $c->current_uri_local_part();

            for ($current_uri_local_part) {
                last if $_ eq '/';
                last if $_ eq '/internal_server_error';
                last if $_ eq '/login';
                last if $_ eq '/register';

                $query->{redirect} = $current_uri_local_part;
            }
        }
    }

    return $c->uri_for_action(@_);
}

=head2 $c->user_registration_enabled()

Returns boolean value if new users are allowed to register. That is
defined by config value C<enable_user_registration> and always true
until the first user (site admin) is registered.

=cut

sub user_registration_enabled {
    my $c = shift;

    $c->model('DB::User')->results_exist
      or return 1;

    return !!$c->config->{enable_user_registration};
}

1;
