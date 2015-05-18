
INSERT INTO quantities (default_unit,name) VALUES (1,"Volumen");
INSERT INTO quantities (default_unit,name) VALUES (3,"Masse");
INSERT INTO quantities (default_unit,name) VALUES (5,"Anzahl");

INSERT INTO units (quantity,to_quantity_default,space,short_name,long_name) VALUES (1,NULL,0,"l","Liter");
INSERT INTO units (quantity,to_quantity_default,space,short_name,long_name) VALUES (1,0.001,0,"ml","Milliliter");
INSERT INTO units (quantity,to_quantity_default,space,short_name,long_name) VALUES (2,NULL,0,"kg","Kilogramm");
INSERT INTO units (quantity,to_quantity_default,space,short_name,long_name) VALUES (2,0.001,0,"g","Gramm");
INSERT INTO units (quantity,to_quantity_default,space,short_name,long_name) VALUES (3,NULL,1,"Stk","Stück");
INSERT INTO units (quantity,to_quantity_default,space,short_name,long_name) VALUES (3,12,1,"Dtz","Dutzend");
INSERT INTO units (quantity,to_quantity_default,space,short_name,long_name) VALUES (NULL,NULL,1,"Rollen","Doppelkeksrollen");

INSERT INTO articles (name,comment) VALUES ("Kartoffeln","");
INSERT INTO articles_units (article,unit) VALUES (1,3);
INSERT INTO articles (name,comment) VALUES ("Zwiebeln","");
INSERT INTO articles_units (article,unit) VALUES (2,4);
INSERT INTO articles_units (article,unit) VALUES (2,5);
INSERT INTO articles (name,comment) VALUES ("Wasser","");
INSERT INTO articles_units (article,unit) VALUES (3,1);
INSERT INTO articles_units (article,unit) VALUES (3,2);
INSERT INTO articles (name,comment) VALUES ("Pfeffer","");
INSERT INTO articles_units (article,unit) VALUES (4,4);
INSERT INTO articles (name,comment) VALUES ("Salz","");
INSERT INTO articles_units (article,unit) VALUES (5,4);

INSERT INTO recipes (servings,name,description) VALUES (4,"Kartoffelsuppe","Lecker!");

INSERT INTO recipe_ingredients (recipe,article,unit,value,comment) VALUES (1,1,3,0.5,"halbes Kg Kartoffeln");
INSERT INTO recipe_ingredients (recipe,article,unit,value,comment) VALUES (1,2,4,50,"50g Zwiebeln");
INSERT INTO recipe_ingredients (recipe,article,unit,value,comment) VALUES (1,3,1,1,"1l Wasser");
INSERT INTO recipe_ingredients (recipe,article,unit,value,comment) VALUES (1,4,4,5,"5g Pfeffer");
INSERT INTO recipe_ingredients (recipe,article,unit,value,comment) VALUES (1,5,4,5,"5g Salz");

INSERT INTO projects (name) VALUES ("SOLA");

INSERT INTO meals (project,date,name,comment) VALUES (1,"2015-08-01","Frühstück","in Gruppen");
INSERT INTO meals (project,date,name,comment) VALUES (1,"2015-08-01","Mittagessen","");
INSERT INTO meals (project,date,name,comment) VALUES (1,"2015-08-01","Abendbrot","Festessen");

INSERT INTO dishes (from_recipe,meal,servings,name,comment) VALUES (1,2,8,"Doppelte Kartoffelsuppe","");

INSERT INTO dish_ingredients (dish,article,unit,value,comment) VALUES (1,1,3,1,"Kg Kartoffeln");
INSERT INTO dish_ingredients (dish,article,unit,value,comment) VALUES (1,2,4,100,"50g Zwiebeln");
INSERT INTO dish_ingredients (dish,article,unit,value,comment) VALUES (1,3,1,2,"1l Wasser");
INSERT INTO dish_ingredients (dish,article,unit,value,comment) VALUES (1,4,4,10,"5g Pfeffer");
INSERT INTO dish_ingredients (dish,article,unit,value,comment) VALUES (1,5,4,10,"5g Salz");

INSERT INTO dishes (from_recipe,meal,servings,name,comment) VALUES (NULL,2,5,"Dessert","");
INSERT INTO dish_ingredients (dish,article,unit,value,comment) VALUES (2,2,5,1,"1 Zwiebel:-)");
