package Coocook::Controller::PurchaseList;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => 'purchase_list' );

=head1 NAME

Coocook::Controller::PurchaseList - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : GET Chained('/project/base') PathPart('purchase_lists') Args(0) {
    my ( $self, $c ) = @_;

    my $lists = $c->project->purchase_lists;

    my $max_date = do {
        my $list = $lists->search( undef, { columns => 'date', order_by => { -desc => 'date' } } )->first;

        $list ? $list->date : undef;
    };

    my $default_date =
        $max_date
      ? $max_date->add( days => 1 )
      : DateTime->today;

    $c->stash(
        default_date => $default_date,
        lists        => [ $lists->sorted->all ],
        title        => "Purchase lists",
    );
}

sub base : Chained('/project/base') PathPart('purchase_list') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( list => $c->project->purchase_lists->find($id) );    # TODO error handling
}

sub edit : GET Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my @items = $c->stash->{list}->items->all;

    my %units = map { $_->id => $_ } $c->model('DB::Unit')->all;

    # collect distinct article IDs (hash may contain duplicates)
    my @article_ids =
      keys %{ { map { $_->get_column('article') => undef } @items } };

    my @articles = $c->model('DB::Article')->search( { id => { -in => \@article_ids } } )->all;

    my %articles = map { $_->id => $_ } @articles;
    my %article_to_section =
      map { $_->id => $_->get_column('shop_section') } @articles;

    my @section_ids =
      keys %{ { map { $_ => undef } values %article_to_section } };

    my @sections = $c->model('DB::ShopSection')->search( { id => { -in => \@section_ids } } )->all;

    my %sections =
      map { $_->id => { name => $_->name, items => [] } } @sections;

    for my $item (@items) {
        my $article = $item->get_column('article');
        my $unit    = $item->get_column('unit');

        my $section = $article_to_section{$article};

        push @{ $sections{$section}{items} },
          {
            id               => $item->id,
            value            => $item->value,
            offset           => $item->offset,
            article          => $articles{$article},
            unit             => $units{$unit},
            comment          => $item->comment,
            ingredients      => [ $item->ingredients->all ],
            convertible_into => [ $item->convertible_into->all ],
          };
    }

    # sort products alphabetically
    for my $section ( values %sections ) {
        $section->{items} = [ sort { $a->{article}->name cmp $b->{article}->name } @{ $section->{items} } ];
    }

    # sort sections
    $c->stash( sections => [ sort { $a->{name} cmp $b->{name} } values %sections ] );

    $c->escape_title( "Purchase list" => $c->stash->{list}->name );
}

sub create : POST Chained('/project/base') PathPart('purchase_lists/create') Args(0) {
    my ( $self, $c ) = @_;

    $c->project->create_related(
        purchase_lists => {
            date => scalar $c->req->param('date'),
            name => scalar $c->req->param('name'),
        }
    );

    $c->detach('redirect');
}

sub update : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{list}->update(
        {
            name => scalar $c->req->param('name'),
        }
    );

    $c->detach('redirect');
}

sub delete : POST Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{list}->delete();

    $c->detach('redirect');
}

sub redirect : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->project_uri( $self->action_for('index') ) );
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
