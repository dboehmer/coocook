package Coocook::Schema::Result::FAQ;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->load_components('Ordered');

__PACKAGE__->table('faqs');

__PACKAGE__->add_columns(
    id          => { data_type => 'int', is_auto_increment => 1 },
    position    => { data_type => 'int', default_value     => 1 },
    anchor      => { data_type => 'text' },
    question_md => { data_type => 'text' },
    answer_md   => { data_type => 'text' },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->position_column('position');

__PACKAGE__->add_unique_constraints( ['anchor'] );

__PACKAGE__->meta->make_immutable;

1;
