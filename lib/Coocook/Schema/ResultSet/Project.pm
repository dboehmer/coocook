package Coocook::Schema::ResultSet::Project;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use DateTime;

extends 'Coocook::Schema::ResultSet';

use feature 'fc';    # Perl v5.16

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::SortByName');

__PACKAGE__->meta->make_immutable;

sub sorted_by_columns { qw< url_name_fc name > }

sub find_by_url_name {
    my ( $self, $url_name ) = @_;

    return $self->find( { url_name_fc => fc $url_name} );
}

sub public {
    my $self = shift;

    return $self->search( { -bool => 'is_public' } );
}

=head2 stale

Returns a new resultset with projects that are completetly in the past.
Indicates that these can be archived.

=cut

sub stale {    # TODO maybe other name? "completed"? then also edit Result->is_stale
    my ( $self, $pivot_date ) = @_;

    my $cmp = { '>=' => $self->format_date( $pivot_date || DateTime->today ) };

    my @rs = (
        $self->correlate('meals')->search( { date => $cmp } ),
        $self->correlate('purchase_lists')->search( { date => $cmp } ),
    );

    return $self->search(
        { -not_bool => [ map { -exists => $_->search( undef, { select => [ \1 ] } )->as_query } @rs ], } );
}

1;
