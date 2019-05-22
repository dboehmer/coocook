package Coocook::Controller::Admin::User;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use feature 'fc';    # Perl v5.16

BEGIN { extends 'Coocook::Controller' }

sub index : GET HEAD Chained('/admin/base') PathPart('users') Args(0)
  RequiresCapability('manage_users') {
    my ( $self, $c ) = @_;

    my $users = $c->model('DB::User')->with_projects_count->search( undef, { order_by => 'name' } );
    my @users = $users->hri->all;

    for my $user (@users) {
        $user->{url} = $c->uri_for_action( '/user/show', [ $user->{name} ] );
        $user->{update_url} = $c->uri_for( $self->action_for('update'), [ $user->{name} ] );

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

sub base : Chained('/admin/base') PathPart('user') CaptureArgs(1) {
    my ( $self, $c, $name ) = @_;

    $c->stash(
        user_object    # don't overwrite $user!
          => $c->model('DB::User')->find( { name_fc => fc $name } ) || $c->detach('/error/not_found')
    );
}

sub update : POST Chained('base') Args(0) RequiresCapability('manage_users') {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user_object};

    if ( defined( my $comment = $c->req->params->get('admin_comment') ) ) {
        $user->set_column( admin_comment => $comment );
    }

    $user->update();

    $c->redirect_detach( $c->uri_for( $self->action_for('index') ) );
}

__PACKAGE__->meta->make_immutable;

1;
