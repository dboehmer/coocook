package Coocook::Helpers;

# ABSTRACT: role with useful Controller helper methods as $c->my_helper(...)

use Moose::Role;
use MooseX::MarkAsMethods autoclean => 1;

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

    $current_uri =~ s! ^ \. / !/!x    #          ./     => /
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

    return $authz->has_capability( $capability, $input );
}

=head2 $c->messages

Returns the L<Coocook::Model::Messages> object for the current session.

    $c->messages->debug("add message");    # call methods on object
    my @messages = @{ $c->messages };     # use as arrayref

=cut

sub messages { return shift->stash->{messages} }

=head2 $c->project_uri($action, @arguments, \%query_params?)

Return URI for project-specific Catalyst action with the current project's C<url_name>
plus any number of C<@arguments> and possibly C<\%query_params>.

    my $uri = $c->project_uri( '/article/edit', $article->id, { key => 'value' } );
    # http://localhost/project/MyProject/article/42?key=value

    my $uri = $c->project_uri( $self->action_for('edit'), $article->id, { key => 'value' } );
    # the same

=cut

sub project_uri {
    my $c      = shift;
    my $action = shift;

    my $project = $c->stash->{project} || die;

    # if last argument is hashref that's the \%query_values argument
    my @query = ref $_[-1] eq 'HASH' ? pop @_ : ();

    return $c->uri_for_action( $action, [ $project->url_name, @_ ], @query );
}

sub project {
    my $c = shift;

    $c->stash->{project};
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

    $c->model('DB::User')->exists
      or return 1;

    return !!$c->config->{enable_user_registration};
}

1;
