package Coocook::Schema::Component::DateTimeHelper;

use strict;
use warnings;

sub format_date     { shift->result_source->schema->storage->datetime_parser->format_date(@_) }
sub format_datetime { shift->result_source->schema->storage->datetime_parser->format_datetime(@_) }

sub parse_date     { shift->result_source->schema->storage->datetime_parser->parse_date(@_) }
sub parse_datetime { shift->result_source->schema->storage->datetime_parser->parse_datetime(@_) }

1;
