package TestDB;

use strict;
use warnings;

use parent 'DBICx::TestDatabase';

sub new {
    my $class = shift;

    my $self = $class->SUPER::new( 'Coocook::Schema', @_ );

    while (<DATA>) {
        $self->storage->dbh_do( sub { $_[1]->do($_) } );
    }

    return $self;
}

1;

__DATA__
INSERT INTO "projects" VALUES(1,'Test');
INSERT INTO "articles" VALUES(1,'',NULL,NULL,NULL,'flour','');
INSERT INTO "articles" VALUES(2,'',NULL,NULL,NULL,'salt','');
INSERT INTO "articles" VALUES(3,'',NULL,NULL,NULL,'water','');
INSERT INTO "articles" VALUES(4,'',NULL,NULL,NULL,'cheese','');
INSERT INTO "meals" VALUES(1,1,'2000-01-01','breakfast','');
INSERT INTO "meals" VALUES(2,1,'2000-01-02','lunch','');
INSERT INTO "meals" VALUES(3,1,'2000-01-03','dinner','');
INSERT INTO "quantities" VALUES(1,'Mass',2);
INSERT INTO "quantities" VALUES(2,'Volume',3);
INSERT INTO "units" VALUES(1,1,0.001,0,'g','grams');
INSERT INTO "units" VALUES(2,1,1.0,0,'kg','kilograms');
INSERT INTO "units" VALUES(3,2,1.0,0,'l','liters');
INSERT INTO "units" VALUES(4,1,1000,0,'t','tons');
INSERT INTO "dishes" VALUES(1,1,NULL,'pancakes',4,NULL,'','Make them really sweet!','');
INSERT INTO "dishes" VALUES(2,2,NULL,'pizza',4,NULL,'','','');
INSERT INTO "dishes" VALUES(3,3,NULL,'bread',4,2,'','Bake bread!','');
INSERT INTO "articles_units" VALUES(1,1);
INSERT INTO "articles_units" VALUES(1,2);
INSERT INTO "articles_units" VALUES(2,1);
INSERT INTO "articles_units" VALUES(3,3);
INSERT INTO "articles_units" VALUES(4,1);
INSERT INTO "articles_units" VALUES(4,2);
INSERT INTO "dish_ingredients" VALUES(1,1,1,0,1,1,500.0,'');
INSERT INTO "dish_ingredients" VALUES(2,2,1,0,2,1,5.0,'');
INSERT INTO "dish_ingredients" VALUES(3,3,1,0,3,3,0.5,'');
INSERT INTO "dish_ingredients" VALUES(4,1,2,0,1,2,1.0,'');
INSERT INTO "dish_ingredients" VALUES(5,2,2,0,3,1,0.5,'');
INSERT INTO "dish_ingredients" VALUES(6,3,2,0,2,1,25.0,'');
INSERT INTO "dish_ingredients" VALUES(7,1,3,1,1,2,1.0,'');
INSERT INTO "dish_ingredients" VALUES(8,2,3,1,2,1,25.0,'');
INSERT INTO "dish_ingredients" VALUES(9,3,3,1,3,3,1.0,'');
INSERT INTO "dish_ingredients" VALUES(10,4,3,0,4,1,500.0,'');
INSERT INTO "recipes" VALUES(1,'pizza','','',4);
INSERT INTO "recipe_ingredients" VALUES(1,1,1,0,1,2,1.0,'');
INSERT INTO "recipe_ingredients" VALUES(2,2,1,0,3,1,0.5,'');
INSERT INTO "recipe_ingredients" VALUES(3,3,1,0,2,1,25.0,'');
