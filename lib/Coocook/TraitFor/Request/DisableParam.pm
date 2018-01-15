package Coocook::TraitFor::Request::DisableParam;

# ABSTRACT: jam $c->req->param() because it's dangerous

use Moose::Role;
use Carp;

sub param {
    croak '$c->req->param() is unsafe and MUST NOT be used. Use $c->req->params->get[_all] instead';
}

1;
