package Coocook::Schema::Result::TermsUser;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('terms_users');

__PACKAGE__->add_columns(
    terms_id => { data_type => 'int' },
    user_id  => { data_type => 'int' },
    approved => { data_type => 'datetime' },
);

__PACKAGE__->set_primary_key(qw< terms_id user_id >);

__PACKAGE__->belongs_to( terms => 'Coocook::Schema::Result::Terms', 'terms_id' );

__PACKAGE__->belongs_to( user => 'Coocook::Schema::Result::User', 'user_id' );

__PACKAGE__->meta->make_immutable;

1;
