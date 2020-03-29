package Coocook::Schema::Result::Quantity;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('quantities');

__PACKAGE__->add_columns(
    id              => { data_type => 'int', is_auto_increment => 1 },
    project_id      => { data_type => 'int' },
    name            => { data_type => 'text' },
    default_unit_id => { data_type => 'int', is_nullable => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( [ 'project_id', 'name' ] );

__PACKAGE__->belongs_to( project => 'Coocook::Schema::Result::Project', 'project_id' );

__PACKAGE__->belongs_to(
    default_unit => 'Coocook::Schema::Result::Unit',
    { 'foreign.id' => 'self.default_unit_id' },
    { join_type    => 'LEFT' }
);

__PACKAGE__->has_many(
    units => 'Coocook::Schema::Result::Unit',
    'quantity_id',
    {
        cascade_delete => 0,    # quantities with units may not be deleted
    }
);

__PACKAGE__->meta->make_immutable;

1;
