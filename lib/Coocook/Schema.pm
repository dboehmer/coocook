package Coocook::Schema;

our $VERSION = 6;    # version of schema definition, not software version!

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'DBIx::Class::Schema::Config';

__PACKAGE__->load_components(
    qw<
      Helper::Schema::QuoteNames
      >
);

__PACKAGE__->meta->make_immutable;

__PACKAGE__->load_namespaces( default_resultset_class => '+Coocook::Schema::ResultSet' );

sub count {
    my $self = shift;

    my $records = 0;
    $records += $self->resultset($_)->count for $self->sources;
    return $records;
}

1;
