package Coocook::Schema::Result::BlacklistEmail;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('blacklist_emails');

__PACKAGE__->add_columns(
    id         => { data_type => 'int', is_auto_increment => 1 },
    email_fc   => { data_type => 'text' },
    email_type => {
        data_type     => 'text',
        default_value => 'cleartext', # SQL default value is for easy manual SQL, code should use sha256_b64
    },
    comment => { data_type => 'text' },
    created => { data_type => 'datetime', default_value => \'CURRENT_TIMESTAMP', set_on_create => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( ['email_fc'] );

1;
