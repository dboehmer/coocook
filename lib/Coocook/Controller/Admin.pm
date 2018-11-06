package Coocook::Controller::Admin;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub base : Chained('/base') PathPart('admin') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        submenu_items => [
            { action => 'admin/faqs',     text => "FAQ" },
            { action => 'admin/projects', text => "Projects" },
            { action => 'admin/users',    text => "Users" },
        ]
    );
}

sub index : GET HEAD Chained('base') PathPart('') Args(0) RequiresCapability('admin_view') { }

sub projects : GET HEAD Chained('base') Args(0) RequiresCapability('admin_view') {
    my ( $self, $c ) = @_;

    # we expect every users to have >=1 projects
    # so better not preload 1:n relationship 'users'
    my @projects = $c->model('DB::Project')->sorted->hri->all;

    my %users = map { $_->{id} => $_ } $c->model('DB::User')->with_projects_count->hri->all;

    for my $project (@projects) {
        $project->{owner} = $users{ $project->{owner} } || die;
        $project->{url} = $c->uri_for_action( '/project/show', [ $project->{url_name} ] );
    }

    for my $user ( values %users ) {
        $user->{url} = $c->uri_for_action( '/user/show', [ $user->{name} ] );
    }

    $c->stash( projects => \@projects );
}

sub users : GET HEAD Chained('base') Args(0) RequiresCapability('admin_view') {
    my ( $self, $c ) = @_;

    my $users = $c->model('DB::User')->with_projects_count->search( undef, { order_by => 'name' } );
    my @users = $users->hri->all;

    for my $user (@users) {
        $user->{url} = $c->uri_for_action( '/user/show', [ $user->{name} ] );

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

sub faqs : GET HEAD Chained('base') PathPart('faq') Args(0) RequiresCapability('admin_view') {
    my ( $self, $c ) = @_;

    my @faqs = $c->model('DB::FAQ')->hri->all;

    for my $faq (@faqs) {
        $faq->{url} = $c->uri_for( $self->action_for('faq'), [ $faq->{id} ] );
    }

    $c->stash(
        faqs        => \@faqs,
        new_faq_url => $c->uri_for( $self->action_for('new_faq') ),
    );
}

sub new_faq : GET HEAD Chained('base') PathPart('faq/new') RequiresCapability('admin_view') {
    my ( $self, $c ) = @_;

    $c->stash(
        admin_faq_url => $c->uri_for( $self->action_for('faqs') ),
        submit_url    => $c->uri_for( $self->action_for('create') ),
        template      => 'admin/faq.tt',
    );
}

sub faq_base : Chained('base') PathPart('faq') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    my $faq = $c->model('DB::FAQ')->find($id)
      or $c->detach('/error/not_found');

    $c->stash( faq => $faq );
}

sub faq : GET HEAD Chained('faq_base') PathPart('') Args(0) RequiresCapability('admin_view') {
    my ( $self, $c ) = @_;

    $c->stash->{faq}{url} = $c->uri_for_action( '/faq/index', \$c->stash->{faq}->anchor );

    $c->stash(
        admin_faq_url => $c->uri_for( $self->action_for('faqs') ),
        submit_url    => $c->uri_for( $self->action_for('update'), [ $c->stash->{faq}->id ] ),
    );
}

sub update : POST Chained('faq_base') Args(0) RequiresCapability('admin_view') {
    my ( $self, $c ) = @_;

    $c->detach('update_or_create');
}

sub create : POST Chained('base') PathPart('faq/create') Args(0) RequiresCapability('admin_view') {
    my ( $self, $c ) = @_;

    $c->stash( faq => $c->model('DB::FAQ')->new_result( {} ) );

    $c->detach('update_or_create');
}

sub update_or_create : Private {
    my ( $self, $c ) = @_;

    my $faq = $c->stash->{faq};

    $faq->set_columns(
        {
            anchor      => $c->req->params->get('anchor'),
            question_md => $c->req->params->get('question'),
            answer_md   => $c->req->params->get('answer'),
        }
    );

    $faq->update_or_insert();

    $c->redirect_detach( $c->uri_for( $self->action_for('faq'), [ $faq->id ] ) );
}

__PACKAGE__->meta->make_immutable;

1;
