use strict;
use warnings;

use Coocook;

my $app = Coocook->apply_default_middlewares(Coocook->psgi_app);
$app;

