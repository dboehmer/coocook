package Coocook::Schema::Result::BlacklistUsername;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('blacklist_usernames');

__PACKAGE__->add_columns(
    id            => { data_type => 'integer', is_auto_increment => 1 },
    username_fc   => { data_type => 'text' },
    username_type => { data_type => 'text', default_value => 'cleartext' },
    comment       => { data_type => 'text' },
    created       => {
        data_type     => 'timestamp without time zone',
        default_value => \'CURRENT_TIMESTAMP',
        set_on_create => 1,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( ['username_fc'] );

1;
