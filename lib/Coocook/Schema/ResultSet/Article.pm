package Coocook::Schema::ResultSet::Article;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

sub sorted { shift->search( undef, { order_by => 'name' } ) }

__PACKAGE__->meta->make_immutable;

1;
