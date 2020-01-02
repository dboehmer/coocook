package Coocook::Schema::Result::BlacklistEmail;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('blacklist_emails');

__PACKAGE__->add_columns(
    id       => { data_type => 'int', is_auto_increment => 1 },
    email_fc => { data_type => 'text' },
    wildcard => { data_type => 'bool', default_value => 0 },
    created  => { data_type => 'datetime', default_value => \'CURRENT_TIMESTAMP', set_on_create => 1 },
    comment  => { data_type => 'text', default_value => '' },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( ['email_fc'] );

1;
