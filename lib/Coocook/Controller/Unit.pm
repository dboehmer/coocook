package Coocook::Controller::Unit;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use Scalar::Util qw(looks_like_number);

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
        units => $c->model('Schema::Unit')->search(
            undef,
            {
                join     => 'quantity',
                order_by => [qw< quantity.name short_name >]
            }
        ),
        quantities => [ $c->model('Schema::Quantity')->sorted->all ],
    );
}

sub create : Local : POST {
    my ( $self, $c, $id ) = @_;
    my $short_name          = scalar $c->req->param('short_name');
    my $long_name           = scalar $c->req->param('long_name');
    my $to_quantity_default = scalar $c->req->param('to_quantity_default');
    my $input_okay          = $self->check_input(
        $c,
        {
            short_name          => $short_name,
            long_name           => $long_name,
            to_quantity_default => $to_quantity_default,
            current_page        => '/units'
        }
    );
    if ($input_okay) {
        $c->model('Schema::Unit')->create(
            {
                short_name          => $short_name,
                long_name           => $long_name,
                quantity            => scalar $c->req->param('quantity') || undef,
                to_quantity_default => $to_quantity_default || undef,
                space               => scalar $c->req->param('space') ? '1' : '0',
            }
        );
        $c->detach('redirect');
    }

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
    my $unit                = $c->model('Schema::Unit')->find($id);
    my $short_name          = scalar $c->req->param('short_name');
    my $long_name           = scalar $c->req->param('long_name');
    my $to_quantity_default = scalar $c->req->param('to_quantity_default');
    my $input_okay          = $self->check_input(
        $c,
        {
            short_name          => $short_name,
            long_name           => $long_name,
            to_quantity_default => $to_quantity_default,
            current_page        => "/unit/$id"
        }
    );
    if ($input_okay) {
        $unit->update(
            {
                short_name          => $short_name,
                long_name           => $long_name,
                to_quantity_default => $to_quantity_default || undef,
                space               => scalar $c->req->param('space') ? '1' : '0',
            }
        );
        $c->detach('redirect');
    }
}

sub edit : Path : Args(1) : GET {
    my ( $self, $c, $id ) = @_;

    my $unit = $c->model('Schema::Unit')->find($id);

    $c->stash(
        unit     => $unit,
        articles => [ $unit->articles->sorted->all ],
    );
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->uri_for_action( $self->action_for('index') ) );
}

#check input of unit when creating and updating a unit
sub check_input : Private {
    my ( $self, $c, $args ) = @_;
    my $shortname           = $args->{short_name};
    my $longname            = $args->{long_name};
    my $to_quantity_default = $args->{to_quantity_default};
    my $current_page        = $args->{current_page};
    my $result              = 0;
    if ( length($shortname) <= 0 ) {
        $c->response->redirect(
            $c->uri_for( $current_page, { error => "Cannot create unit with empty short name!" } ) );
    }
    elsif ( length($longname) <= 0 ) {
        $c->response->redirect(
            $c->uri_for( $current_page, { error => "Cannot create unit with empty long name!" } ) );
    }
    elsif ( !( looks_like_number($to_quantity_default) ) ) {
        $c->response->redirect(
            $c->uri_for(
                $current_page,
                { error => "Please supply a valid number in 'Factor to quantity's default unit'.\n E.g.: 1.33" }
            )
        );
    }
    else {
        $result = 1;
    }
    return $result;
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
