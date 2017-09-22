package Coocook::Model::PurchaseList;

use Moose;

has list => (
    is       => 'ro',
    isa      => 'Coocook::Schema::Result::PurchaseList',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

sub by_section {
    my $self = shift;

    my $list    = $self->list;
    my $project = $list->project;

    my @items = $list->items->all;

    my %units = map { $_->id => $_ } $project->units->all;

    # collect distinct article IDs (hash may contain duplicates)
    my @article_ids =
      keys %{ { map { $_->get_column('article') => undef } @items } };

    my @articles = $project->articles->search( { id => { -in => \@article_ids } } )->all;

    my %articles = map { $_->id => $_ } @articles;
    my %article_to_section =
      map { $_->id => $_->get_column('shop_section') } @articles;

    my @section_ids =
      keys %{ { map { $_ => undef } values %article_to_section } };

    my @sections = $project->shop_sections->search( { id => { -in => \@section_ids } } )->all;

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
    return [ sort { $a->{name} cmp $b->{name} } values %sections ];
}

1;
