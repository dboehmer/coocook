package Coocook::Schema::ResultSet;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::NonMoose;

extends 'DBIx::Class::ResultSet';

__PACKAGE__->load_components(
    qw<
      Helper::ResultSet::CorrelateRelationship
      Helper::ResultSet::IgnoreWantarray
      Helper::ResultSet::Me
      >
);

__PACKAGE__->meta->make_immutable;

sub format_date {
    my ( $self, $date ) = @_;

    return $self->result_source->schema->storage->datetime_parser->format_date($date);
}

sub format_datetime {
    my ( $self, $datetime ) = @_;

    return $self->result_source->schema->storage->datetime_parser->format_datetime($datetime);
}

1;
