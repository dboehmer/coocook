package Coocook::Controller::Admin::User;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use feature 'fc';    # Perl v5.16

BEGIN { extends 'Coocook::Controller' }

sub index : GET HEAD Chained('/admin/base') PathPart('users') Args(0)
  RequiresCapability('manage_users') {
    my ( $self, $c ) = @_;

    $c->stash( users => \my @users );

    {
        my $users = $c->model('DB::User')->with_projects_count->search( undef, { order_by => 'name_fc' } );

        while ( my $user = $users->next ) {
            push @users,
              $user->as_hashref(
                status => $user->status_description,
                url    => $c->uri_for( $self->action_for('show'), [ $user->name ] ),
              );
        }
    }
}

sub base : Chained('/admin/base') PathPart('user') CaptureArgs(1) {
    my ( $self, $c, $name ) = @_;

    my $user = $c->model('DB::User')->find( { name_fc => fc $name } ) || $c->detach('/error/not_found');

    $c->stash(
        user_object => $user,    # don't overwrite $user!

        locked_roles => {

            # admins may not toggle their own 'site_owner' state
            # non-site-owners may not gain that privilege, of course
            # site owners should not loose that state and leave the site locked up
            site_owner => !$c->has_capability( toggle_site_owner => { user_object => $user } ),
        },

        global_roles => [
            qw<
              private_projects
              site_owner
              >
        ],
    );
}

sub show : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('manage_users') {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user_object};

    my ( $status_code => $status_description ) = $user->status;

    if ( $c->has_capability('discard_user') ) {
        $c->stash( discard_url => $c->uri_for( $self->action_for('discard'), [ $user->name ] ) );
    }

    my $permissions = $user->projects_users->search(
        undef,
        {
            prefetch => 'project',
            order_by => 'project.url_name_fc',
        }
    );

    $c->stash(
        status             => $status_description,
        permissions        => \my @permissions,
        public_profile_url => $c->uri_for_action( '/user/show', [ $user->name ] ),
        update_url         => $c->uri_for( $self->action_for('update'), [ $user->name ] ),
        roles              => { map { $_ => 1 } $user->roles },
    );

    while ( my $permission = $permissions->next ) {
        my $project = $permission->project;

        # !!! WARNING !!!
        # locally set owner to existing Result::User object
        # otherwise $project->as_hashref retrieves every user related as owner
        #
        # THIS MUST NOT BE STORED TO THE DATABASE.
        $project->owner( $c->user->get_object );

        $project = $project->as_hashref;

        $project->{url} = $c->uri_for_action( '/project/show', [ $project->{url_name} ] );

        push @permissions,
          {
            role    => $permission->role,
            project => $project,
          };
    }
}

sub update : POST Chained('base') Args(0) RequiresCapability('manage_users') {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user_object};

    $user->txn_do(
        sub {
            if ( defined( my $comment = $c->req->params->get('admin_comment') ) ) {
                $user->set_column( admin_comment => $comment );
            }

            if ( $c->req->params->get('update_roles') ) {
                my %checked = map { $_ => 1 } $c->req->params->get_all('roles');

                {
                    my $roles        = $user->roles_users;
                    my $locked_roles = $c->stash->{locked_roles};

                    if ( my @locked_roles = grep { $locked_roles->{$_} } keys %$locked_roles ) {
                        $roles = $roles->search( { role => { -not_in => \@locked_roles } } );
                    }

                    $roles->delete();
                }

                for my $role ( @{ $c->stash->{global_roles} } ) {
                    $checked{$role}
                      or next;

                    $c->stash->{locked_roles}{$role}
                      and $c->detach('/error/bad_request');

                    $user->create_related( roles_users => { role => $role } );
                }
            }

            $user->update();
        }
    );

    $c->redirect_detach( $c->uri_for( $self->action_for('show'), [ $user->name ] ) );
}

sub discard : POST Chained('base') Args(0) RequiresCapability('discard_user') {
    my ( $self, $c ) = @_;

    $c->model('DB')->txn_do(
        sub {
            $c->req->params->get('blacklist')
              and $c->stash->{user_object}->blacklist( comment => "discarded by " . $c->user->name );

            $c->stash->{user_object}->delete();
        }
    );

    $c->redirect_detach( $c->uri_for( $self->action_for('index') ) );
}

__PACKAGE__->meta->make_immutable;

1;
