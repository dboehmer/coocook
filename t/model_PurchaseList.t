use Test2::V0;

use Coocook::Model::PurchaseList;
use DateTime;
use Test::Memory::Cycle;
use Test::MockObject;

use lib 't/lib';
use TestDB;

my $db = TestDB->new;

ok my $list =
  Coocook::Model::PurchaseList->new( list => $db->resultset('PurchaseList')->find(1) );

ok my $sections = $list->shop_sections;

is $sections => array {
    item hash {
        field id         => 1;
        field project_id => 1;
        field name       => "bakery products";
        field items      => array {
            item hash {
                field value       => 1000;
                field unit        => hash { field short_name => "g";     etc() };
                field article     => hash { field name       => "flour"; etc() };
                field ingredients => array {
                    item hash {
                        field id   => 1;
                        field dish => hash {
                            field name => "pancakes";
                            field meal => hash {
                                field id   => 1;
                                field date => object {
                                    prop isa => 'DateTime';
                                    call ymd => '2000-01-01';
                                };
                                field name => "breakfast";
                                etc();
                            };
                            etc();
                        };
                        etc();
                    };
                    item hash { field id => 4; etc() },
                };
                etc();
            };
            item hash {
                field value       => 37.5;
                field unit        => hash { field short_name => "g";    etc() };
                field article     => hash { field name       => "salt"; etc() };
                field ingredients => array {
                    item hash { field id => 6; etc() };
                    item hash { field id => 8; etc() };
                };
                etc();
            };
        };
    };
},
  "->shop_sections()";

memory_cycle_ok $sections, "result of by_section() is free of memory cycles";

done_testing;
