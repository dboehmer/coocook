package Coocook::Controller::Print;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use utf8;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Print - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub auto : Private {
    my ( $self, $c ) = @_;

    push @{ $c->stash->{css} }, 'print.css';
}

sub index : Path Args(0) {
    my ( $self, $c ) = @_;

    my $project = $c->stash->{my_project};

    my @days =
      map { $_->date }
      $project->meals->search( undef, { columns => 'date', distinct => 1 } )
      ->all;

    my $lists =
      $project->purchase_lists->search( undef, { order_by => 'date' } );

    my @projects = $c->model('Schema::Project')->all;

    $c->stash(
        days     => \@days,
        lists    => $lists,
        projects => \@projects,
    );
}

sub day : Local Args(3) {
    my ( $self, $c, $year, $month, $day ) = @_;

    my $dt = DateTime->new(
        year  => $year,
        month => $month,
        day   => $day,
    );

    my $meals = $c->model('Schema::Meal')->search(
        {
            date => $dt->ymd,
        }
    );

    $c->stash(
        day   => $dt,
        meals => $meals,
    );
}

sub project : Local Args(1) {
    my ( $self, $c, $id ) = @_;

    my $project = $c->model('Schema::Project')->find($id);

    my @days = (
        {
            date  => DateTime->today,
            meals => [
                {
                    name   => "Frühstück",
                    dishes => [qw<Eier Brötchen>],
                },
                {
                    name   => "Mittagessen",
                    dishes => [qw<Käsespätzle Pudding>],
                },
            ],
        },
        {
            date  => DateTime->today->add( days => 1 ),
            meals => [
                {
                    name   => "Abschluss-Brunch",
                    dishes => ["Reste"],
                }
            ],
        },
    );

    $c->stash(
        project => $project,
        days    => \@days,
    );
}

sub purchase_list : Local Args(1) {
    my ( $self, $c, $id ) = @_;

    my $list = $c->model('Schema::PurchaseList')->find($id);

    my @items = $list->items->all;

    my %units = map { $_->id => $_ } $c->model('Schema::Unit')->all;

    # collect distinct article IDs (hash may contain duplicates)
    my @article_ids =
      keys %{ { map { $_->get_column('article') => undef } @items } };

    my @articles = $c->model('Schema::Article')
      ->search( { id => { -in => \@article_ids } } );

    my %articles = map { $_->id => $_ } @articles;
    my %article_to_section =
      map { $_->id => $_->get_column('shop_section') } @articles;

    my @section_ids =
      keys %{ { map { $_ => undef } values %article_to_section } };

    my @sections = $c->model('Schema::ShopSection')
      ->search( { id => { -in => \@section_ids } } );

    my %sections =
      map { $_->id => { name => $_->name, items => [] } } @sections;

    for my $item (@items) {
        my $article = $item->get_column('article');
        my $unit    = $item->get_column('unit');

        my $section = $article_to_section{$article};

        push @{ $sections{$section}{items} },
          {
            value       => $item->value,
            offset      => $item->offset,
            article     => $articles{$article},
            unit        => $units{$unit},
            comment     => $item->comment,
            ingredients => [ $item->ingredients ],
          };
    }

    # sort products alphabetically
    for my $section ( values %sections ) {
        $section->{items} =
          [ sort { $a->{article}->name cmp $b->{article}->name }
              @{ $section->{items} } ];
    }

    # sort sections
    my $sections = [ sort { $a->{name} cmp $b->{name} } values %sections ];

    $c->stash( sections => $sections );
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
