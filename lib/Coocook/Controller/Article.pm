package Coocook::Controller::Article;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Article - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->stash(
        default_shelf_life_days   => 7,
        default_preorder_servings => 10,
        default_preorder_workdays => 3,
    );

    my $quantities = $c->model('Schema::Quantity');
    $quantities = $quantities->search(
        undef,
        {
            prefetch => 'units',
            order_by => [ $quantities->me('name'), 'units.short_name', ],
        }
    );

    $c->stash(
        shop_sections => [ $c->model('Schema::ShopSection')->sorted->all ],
        quantities    => [ $quantities->all ],
    );
}

sub index : Path('/articles') : Args(0) {
    my ( $self, $c ) = @_;

    my $articles = $c->model('Schema::Article')->sorted;

    $c->stash( articles => $articles );
}

sub edit : GET Path Args(1) {
    my ( $self, $c, $id ) = @_;

    my $article = $c->model('Schema::Article')->find($id)
      or die "Can't find article";    # TODO serious error message

    $c->stash( article => $article );
}

sub create : Local : POST {
    my ( $self, $c, $id ) = @_;

    my $units = $c->model('Schema::Unit')->search(
        {
            id => { -in => [ $c->req->param('units') ] },
        }
    );

    my $tags =
      $c->model('Schema::Tag')->from_names( scalar $c->req->param('tags') );

    my $shelf_life_days = undef;

    if ( $c->req->param('shelf_life') and defined( my $days = $c->req->param('shelf_life_days') ) ) {
        $shelf_life_days = $days;
    }

    my ( $preorder_servings, $preorder_workdays );

    if ( my $s = $c->req->param('preorder_servings')
        and defined( my $wd = $c->req->param('preorder_workdays') ) )
    {
        $preorder_servings = $s;
        $preorder_workdays = $wd;
    }

    $c->model('Schema')->schema->txn_do(
        sub {
            my $article = $c->model('Schema::Article')->create(
                {
                    name              => scalar $c->req->param('name'),
                    comment           => scalar $c->req->param('comment'),
                    shop_section      => scalar $c->req->param('shop_section'),
                    shelf_life_days   => $shelf_life_days,
                    preorder_servings => $preorder_servings,
                    preorder_workdays => $preorder_workdays,
                }
            );

            $article->set_tags(  [ $tags->all ] );
            $article->set_units( [ $units->all ] );
        }
    );
    $c->detach('redirect');
}

sub delete : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Article')->find($id)->delete;
    $c->detach('redirect');
}

sub update : POST Path Args(1) {
    my ( $self, $c, $id ) = @_;

    my $units = $c->model('Schema::Unit')->search(
        {
            id => { -in => [ $c->req->param('units') ] },
        }
    );

    my $tags =
      $c->model('Schema::Tag')->from_names( scalar $c->req->param('tags') );

    my $article = $c->model('Schema::Article')->find($id);

    $c->model('Schema')->schema->txn_do(
        sub {
            $article->set_tags(  [ $tags->all ] );
            $article->set_units( [ $units->all ] );
            $article->set_columns(
                {
                    name         => scalar $c->req->param('name'),
                    comment      => scalar $c->req->param('comment'),
                    shop_section => scalar $c->req->param('shop_section'),
                }
            );
            if ( scalar $c->req->param('shelf_life') ) {
                $article->set_columns(
                    {
                        shelf_life_days =>
                          scalar $c->req->param('shelf_life_days')
                    }
                );
            }
            else {
                $article->set_columns( { shelf_life_days => undef } );
            }
            if ( scalar $c->req->param('preorder') ) {
                $article->set_columns(
                    {
                        preorder_servings =>
                          scalar $c->req->param('preorder_servings'),
                        preorder_workdays =>
                          scalar $c->req->param('preorder_workdays'),
                    }
                );
            }
            else {
                $article->set_columns(
                    { preorder_servings => undef, preorder_workdays => undef, }
                );
            }
            $article->update;
        }
    );

    $c->detach('redirect');
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
