package Coocook::Schema::Result::TermsUser;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('terms_users');

__PACKAGE__->add_columns(
    terms    => { data_type => 'int' },
    user     => { data_type => 'int' },
    approved => { data_type => 'datetime' },
);

__PACKAGE__->set_primary_key(qw< terms user >);

__PACKAGE__->belongs_to( terms => 'Coocook::Schema::Result::Terms' );

__PACKAGE__->belongs_to( user => 'Coocook::Schema::Result::User' );

__PACKAGE__->meta->make_immutable;

1;
