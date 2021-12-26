use Test2::V0;

use Coocook::Model::Ingredients;

use lib 't/lib/';
use TestDB;

plan(7);

my $schema = TestDB->new();

ok my $ingredients =
  Coocook::Model::Ingredients->new( recipe => $schema->resultset('Recipe')->find(1) ),
  "ingredients from recipe";

is $ingredients->as_arrayref => array {
    item hash {
        field value   => 0.5;
        field unit    => object { call short_name => 'l' };
        field article => object { call name       => 'water' };
        etc();
    };
    item hash {
        field value   => 1;
        field unit    => object { call short_name => 'kg' };
        field article => object { call name       => 'flour' };
        etc();
    };
    item hash {
        field value   => 15;
        field unit    => object { call short_name => 'g' };
        field article => object { call name       => 'salt' };
        etc();
    };
    item hash {
        field value   => 10;
        field unit    => object { call short_name => 'g' };
        field article => object { call name       => 'salt' };
        field comment => 'if you like salty';
        etc();
    };
},
  "as_arrayref()";

ok $ingredients->factor(42), "set factor";

is $ingredients->as_arrayref => array {
    item hash { field value => 21;  etc() };
    item hash { field value => 42;  etc() };
    item hash { field value => 630; etc() };
    item hash { field value => 420; etc() };
},
  "multiplied values";

is my $articles = $ingredients->all_articles => array {
    item object {
        call name => 'cheese';
        call_list units => array {
            item object { call short_name => 'g' };
            item object { call short_name => 'kg' };
        };
    };
    item object {
        call name => 'flour';
        call_list units => array {
            item object { call short_name => 'g' };
            item object { call short_name => 'kg' };
        };
    };
    item object {
        call name => 'love';
        call_list units => [];
    };
    item object {
        call name => 'salt';
        call_list units => array {
            item object { call short_name => 'g' };
        };
    };
    item object {
        call name => 'water';
        call_list units => array {
            item object { call short_name => 'l' };
        };
    };
},
  "all_articles";

todo "fetch objects only once" => sub {
    is(
        ( $articles->[0]->units )[0] => exact_ref( ( $articles->[1]->units )[1] ),
        "kg of cheese and kg of flour are the same Result object"
    );
};

is my $units = $ingredients->all_units => array {
    item object { call short_name => 'g';  call long_name => 'grams' };
    item object { call short_name => 'kg'; call long_name => 'kilograms' };
    item object { call short_name => 'l';  call long_name => 'liters' };
},
  "all_units";
