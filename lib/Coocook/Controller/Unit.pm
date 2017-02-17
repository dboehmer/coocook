package Coocook::Controller::Unit;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Unit - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path('/units') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        units => $c->model('Schema::Unit')->search_rs(
            undef,
            {
                join     => 'quantity',
                order_by => [qw< quantity.name short_name >]
            }
        ),
        quantities => [ $c->model('Schema::Quantity')->sorted ],
    );
}

sub create : Local : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Unit')->create(
        {
            short_name          => scalar $c->req->param('short_name'),
            long_name           => scalar $c->req->param('long_name'),
            quantity            => scalar $c->req->param('quantity') || undef,
            to_quantity_default => scalar $c->req->param('to_quantity_default')
              || undef,
            space => scalar $c->req->param('space') ? '1' : '0',
        }
    );
    $c->detach('redirect');
}

sub delete : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Unit')->find($id)->delete;
    $c->detach('redirect');
}

sub make_quantity_default : Local Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Unit')->find($id)->make_quantity_default;
    $c->detach('redirect');
}

sub update : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Unit')->find($id)->update(
        {
            short_name => scalar $c->req->param('short_name'),
            long_name  => scalar $c->req->param('long_name'),
			quantity            => scalar $c->req->param('quantity') || undef,
            to_quantity_default => scalar $c->req->param('to_quantity_default')
              || undef,
            space => scalar $c->req->param('space') ? '1' : '0',
        }
    );
    $c->detach('redirect');
}

sub edit : Path: Args(1) : GET {
	my ( $self, $c, $id ) = @_;
	my $unit = $c->model('Schema::Unit')->find($id);
	$c->stash(
        unit => $unit,
		quantities => [ $c->model('Schema::Quantity')->sorted ],
	);
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->uri_for_action( $self->action_for('index') ) );
}

=encoding utf8

=head1 AUTHOR

Daniel Böhmer,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
