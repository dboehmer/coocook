package Coocook::Controller::Email;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

sub verification : Private {
    my ( $self, $c, $user ) = @_;

    my $name = $c->config->{name};

    local $c->stash->{wrapper} = undef;    # disable default wrapper

    $c->stash(
        email => {
            from     => 'coocook@example.com',
            to       => $user->email,
            subject  => "Verify your Account at $name",
            template => 'email/verify.tt',
        },
        verification_url => $c->uri_for_action( '/user/verify', [ $user->token ] ),
    );

    $c->forward( $c->view('Email::Template') );
}

__PACKAGE__->meta->make_immutable;

1;
