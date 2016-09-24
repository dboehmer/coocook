package Catalyst::Script::Deploy;

# TODO Release on CPAN! :-)

use Module::Load;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

with 'Catalyst::ScriptRole';

has drop_tables => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => "Drop tables before creating them",
);

has model_class => (    # can be overriden in application-specific child class
    is      => 'rw',
    isa     => 'Str',
    default => 'Schema',
    traits  => ['NoGetopt'],
);

has trace => (
    is  => 'rw',
    isa => 'Bool',
    documentation =>
      "Trace SQL commands, equivalent to setting \$ENV{DBIC_TRACE}=1",
);

sub run {
    my $self = shift;

    my $app = $self->application_name;
    load $app;
    my $model = $app->model( $self->model_class );

    my $schema = $model->schema;
    $self->trace and $schema->storage->debug(1);
    $schema->deploy( { add_drop_table => $self->drop_tables } );
}

# use MooseX::Getopt's original print_usage_text for automatic text generation
sub print_usage_text { goto &MooseX::Getopt::print_usage_text }

# hide attribute 'loader_class' in help text
has '+loader_class' => ( traits => ['NoGetopt'] );

__PACKAGE__->meta->make_immutable;

1;
