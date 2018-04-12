package Coocook::Schema::Component::ProxyMethods;

# ABSTRACT: call ResultSource or Schema methods by shorthand methods from Result[Set]

use strict;
use warnings;

# DateTime formatting
sub format_date     { shift->result_source->schema->storage->datetime_parser->format_date(@_) }
sub format_datetime { shift->result_source->schema->storage->datetime_parser->format_datetime(@_) }

# DateTime parsing
sub parse_date     { shift->result_source->schema->storage->datetime_parser->parse_date(@_) }
sub parse_datetime { shift->result_source->schema->storage->datetime_parser->parse_datetime(@_) }

# start transactions
sub txn_do { shift->result_source->schema->txn_do(@_) }

1;
