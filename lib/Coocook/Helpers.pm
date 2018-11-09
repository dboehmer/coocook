package Coocook::Helpers;

# ABSTRACT: role with useful Controller helper methods as $c->my_helper(...)

use HTML::Entities ();
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
    $current_uri =~ s/\.//;

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

sub encode_entities {
    my ( $self, $text ) = @_;
    return HTML::Entities::encode_entities($text);
}

=head2 $c->escape_title( $title, $text )

Set C<< $c->stash->{title} >> and C<< $c->stash->{html_title} >> in 1 step.

    $c->escape_title( User => $user->display_name ); # Cool guy :->
    # html_title: User <em>Cool guy:-&gt;</em>
    #      title: User "Cool guy:->"
    #             can be escaped with TT filter 'html' to: &quot;Cool guy:-&gt;&quot;

=cut

sub escape_title {
    my ( $self, $title, $text ) = @_;

    $self->stash(
        title      => "$title \"$text\"",
        html_title => "$title <em>" . $self->encode_entities($text) . "</em>",
    );
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

    $input            //= {};
    $input->{project} //= $c->project;
    $input->{user}    //= $c->user;

    return $c->model('Authorization')->has_capability( $capability, $input );
}

=head2 $c->project_uri($action, @arguments, \%query_params?)

Return URI for project-specific Catalyst action with the current project's C<url_name>
plus any number of C<@arguments> and possibly C<\%query_params>.

    my $uri = $c->project_uri( '/article/edit', $article->id, { error => "Name must not be empty" } );
    # http://localhost/project/MyProject/article/42?error=Name%20must%20not%20be%20empty

    my $uri = $c->project_uri( $self->action_for('edit'), $article->id, { error => "Name must not be empty" } );
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

=head2 $c->redirect_detach($uri)

Set HTTP C<Location:> header to redirect URI and detach from Catalyst request flow in 1 step.
Method never returns.

=cut

sub redirect_detach {
    my ( $c, $uri ) = @_;

    $c->response->redirect($uri);
    $c->detach;
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
