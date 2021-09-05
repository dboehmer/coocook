package Coocook::View::JSON;

# ABSTRACT: view for Coocook to create

use Moose;

use MooseX::MarkAsMethods autoclean => 1;
use MooseX::NonMoose;

extends 'Catalyst::View::JSON';

__PACKAGE__->meta->make_immutable;

__PACKAGE__->config( expose_stash => 'json_data', );

1;
