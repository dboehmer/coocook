package Coocook::Controller::PurchaseList;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config( namespace => 'purchase_list' );

=head1 NAME

Coocook::Controller::PurchaseList - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path('/purchase_lists') Args(0) {
    my ( $self, $c ) = @_;

    my $project = $c->stash->{my_project};

    my $lists =
      $c->model('Schema::PurchaseList')->search( { project => $project->id } );

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
        lists        => $lists->search( undef, { order_by => 'date' } ),
    );
}

sub edit : Path Args(1) {
    my ( $self, $c, $id ) = @_;

    my $list = $c->model('Schema::PurchaseList')->find($id);

    my @items = $list->items->all;

    my %units = map { $_->id => $_ } $c->model('Schema::Unit')->all;

    # collect distinct article IDs (hash may contain duplicates)
    my @article_ids =
      keys %{ { map { $_->get_column('article') => undef } @items } };

    my @articles = $c->model('Schema::Article')->search( { id => { -in => \@article_ids } } );

    my %articles = map { $_->id => $_ } @articles;
    my %article_to_section =
      map { $_->id => $_->get_column('shop_section') } @articles;

    my @section_ids =
      keys %{ { map { $_ => undef } values %article_to_section } };

    my @sections = $c->model('Schema::ShopSection')->search( { id => { -in => \@section_ids } } );

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
    my $sections = [ sort { $a->{name} cmp $b->{name} } values %sections ];

    $c->stash(
        list     => $list,
        sections => $sections,
    );
}

sub create : Local POST {
    my ( $self, $c ) = @_;

    $c->model('Schema::PurchaseList')->create(
        {
            date    => scalar $c->req->param('date'),
            name    => scalar $c->req->param('name'),
            project => scalar $c->req->param('project'),
        }
    );

    $c->detach('redirect');
}

sub update : Args(1) Local POST {
    my ( $self, $c, $id ) = @_;

    my $list = $c->model('Schema::PurchaseList')->find($id);

    $list->update(
        {
            name => scalar $c->req->param('name'),
        }
    );

    $c->detach('redirect');
}

sub delete : Local Args(1) POST {
    my ( $self, $c, $id ) = @_;

    $c->model('Schema::PurchaseList')->find($id)->delete;

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
