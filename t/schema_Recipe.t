use Test2::V0;

use lib 't/lib';
use TestDB;

subtest duplicate => sub {
    my $db = TestDB->new;

    my $recipe = $db->resultset('Recipe')->find(1);

    ok my $clone = $recipe->duplicate( { name => 'clone recipe' } ), "clone";

    isa_ok $clone => 'Coocook::Schema::Result::Recipe';

    isnt $clone->id => $recipe->id, "IDs differ";

    is $clone->ingredients->count => $recipe->ingredients->count, "number of ingredients equal";
};

done_testing;
