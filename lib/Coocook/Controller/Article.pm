package Coocook::Controller::Article;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Article - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path('/articles') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        articles      => $c->model('Schema::Article'),
        shop_sections => [ $c->model('Schema::ShopSection')->all ],
        units         => [ $c->model('Schema::Unit')->all ],
    );
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

    $c->model('Schema')->schema->txn_do(
        sub {
            my $article = $c->model('Schema::Article')->create(
                {
                    name         => $c->req->param('name'),
                    comment      => $c->req->param('comment'),
                    shop_section => scalar $c->req->param('shop_section'),
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

sub update : Local : Args(1) : POST {
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
            $article->update(
                {
                    name         => $c->req->param('name'),
                    comment      => $c->req->param('comment'),
                    shop_section => $c->req->param('shop_section'),
                }
            );
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
