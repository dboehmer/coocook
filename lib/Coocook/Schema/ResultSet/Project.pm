package Coocook::Schema::ResultSet::Project;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

use feature 'fc';    # Perl v5.16

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::SortByName');

__PACKAGE__->meta->make_immutable;

sub find_by_url_name {
    my ( $self, $url_name ) = @_;

    return $self->find( { url_name_fc => fc $url_name} );
}

1;
