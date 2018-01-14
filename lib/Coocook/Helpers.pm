package Coocook::Helpers;

# ABSTRACT: role with useful Controller helper methods as $c->my_helper(...)

use HTML::Entities ();
use Moose::Role;
use MooseX::MarkAsMethods autoclean => 1;

sub encode_entities {
    my ( $self, $text ) = @_;
    return HTML::Entities::encode_entities($text);
}

sub escape_title {
    my ( $self, $title, $text ) = @_;

    $self->stash(
        title      => "$title \"$text\"",
        html_title => "$title <em>" . $self->encode_entities($text) . "</em>",
    );
}

sub has_capability {
    my ( $c, $capability, $input ) = @_;

    $input            //= {};
    $input->{project} //= $c->project;
    $input->{user}    //= $c->user;

    return $c->model('Authorization')->has_capability( $capability, $input );
}

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

sub redirect_detach {
    my ( $c, $uri ) = @_;

    $c->response->redirect($uri);
    $c->detach;
}

# proxy
sub txn_do { shift->model('DB')->schema->txn_do(@_) }

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
