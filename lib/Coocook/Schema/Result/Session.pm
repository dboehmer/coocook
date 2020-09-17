package Coocook::Schema::Result::Session;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('sessions');

__PACKAGE__->add_columns(
    id           => { data_type => 'text' },
    expires      => { data_type => 'integer', is_nullable => 1 },
    session_data => { data_type => 'text',    is_nullable => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->meta->make_immutable;

1;
