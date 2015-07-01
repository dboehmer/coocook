package Coocook::Controller::Print;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Coocook::Controller::Print - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path Args(0) { }

sub shopping_list : Local Args(1) {
    my ( $self, $c, $id ) = @_;

    my $sections = [
        {
            name  => "Backwaren",
            items => [
                {
                    value       => 23,
                    unit        => { short_name => "Kg" },
                    offset      => -5,
                    comment     => "Noch 5kg im Vorrat",
                    article     => { name => "Haferflocken" },
                    ingredients => [
                        {
                            date    => "2014-08-01",
                            value   => 20,
                            unit    => "Kg",
                            dish    => "SOLA-Pampe",
                            comment => "Hochwertige kaufen!"
                        },
                        {
                            date  => "2014-08-02",
                            value => 3,
                            unit  => "Kg",
                            dish  => "Eklige Suppe"
                        },
                    ],
                },
                {
                    value       => 100,
                    unit        => { short_name => "Stk" },
                    offset      => undef,
                    comment     => undef,
                    article     => { name => "Äpfel" },
                    ingredients => [
                        {
                            date  => "2014-08-02",
                            value => 100,
                            unit  => "Stk",
                            dish  => "Dessert"
                        },
                    ],
                },
            ],
        },
        {
            name  => "Obst & Gemüse",
            items => [],
        },
    ];

    # sort products alphabetically
    for my $section (@$sections) {
        $section->{items} =
          [ sort { $a->{article}{name} cmp $b->{article}{name} }
              @{ $section->{items} } ];
    }

    # sort sections
    $sections = [ sort { $a->{name} cmp $b->{name} } @$sections ];

    $c->stash( sections => $sections );

    push @{ $c->stash->{css} }, 'print.css';
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
