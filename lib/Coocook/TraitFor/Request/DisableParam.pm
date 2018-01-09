package Coocook::TraitFor::Request::DisableParam;

use Moose::Role;
use Carp;

sub param {
    croak '$c->req->param() is unsafe and MUST NOT be used. Use $c->req->params->get[_all] instead';
}

1;
