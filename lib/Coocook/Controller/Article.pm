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
        articles => $c->model('Schema::Article'),
        units    => [ $c->model('Schema::Unit')->all ],
    );
}

sub create : Local : POST {
    my ( $self, $c, $id ) = @_;

    my $units = $c->model('Schema::Unit')->search(
        {
            id => { -in => [ $c->req->param('units') ] },
        }
    );

    $c->model('Schema')->schema->txn_do(
        sub {
            my $article = $c->model('Schema::Article')->create(
                {
                    name    => $c->req->param('name'),
                    comment => $c->req->param('comment'),
                }
            );

            $article->set_units( [ $units->all ] );
        }
    );
    $c->response->redirect( $c->uri_for_action('/article/index') );
}

sub delete : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;
    $c->model('Schema::Article')->find($id)->delete;
    $c->response->redirect( $c->uri_for_action('/article/index') );
}

sub update : Local : Args(1) : POST {
    my ( $self, $c, $id ) = @_;

    my $units = $c->model('Schema::Unit')->search(
        {
            id => { -in => [ $c->req->param('units') ] },
        }
    );

    my $article = $c->model('Schema::Article')->find($id);

    $c->model('Schema')->schema->txn_do(
        sub {
            $article->set_units( [ $units->all ] );
            $article->update(
                {
                    name    => $c->req->param('name'),
                    comment => $c->req->param('comment'),
                }
            );
        }
    );

    $c->response->redirect( $c->uri_for_action('/article/index') );
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
