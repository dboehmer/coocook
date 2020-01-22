use strict;
use warnings;

use Test::Most;

use_ok 'Coocook::Util';

my $name          = '!Geheimes - Projekt!';
my $original_name = "$name";

is Coocook::Util::url_name($name) => '-Geheimes-Projekt-',
  "url_name()";

is_deeply Coocook::Util::url_names_hashref($name) => {
    url_name    => '-Geheimes-Projekt-',
    url_name_fc => '-geheimes-projekt-',
  },
  "url_names_hash_list()";

is $name => $original_name, "original value untouched";

done_testing();
