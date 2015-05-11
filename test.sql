
INSERT INTO quantities (name) VALUES ("Volumen");
INSERT INTO quantities (name) VALUES ("Masse");
INSERT INTO quantities (name) VALUES ("Anzahl");

INSERT INTO units (quantity,short_name,long_name) VALUES (1,"l","Liter");
INSERT INTO units (quantity,short_name,long_name) VALUES (1,"ml","Milliliter");
INSERT INTO units (quantity,short_name,long_name) VALUES (2,"kg","Kilogramm");
INSERT INTO units (quantity,short_name,long_name) VALUES (2,"g","Gramm");
INSERT INTO units (quantity,short_name,long_name) VALUES (3,"Stk","Stück");
INSERT INTO units (quantity,short_name,long_name) VALUES (3,"Dtz","Dutzend");

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

INSERT INTO ingredients (recipe,article,unit,value,comment) VALUES (1,1,3,0.5,"halbes Kg Kartoffeln");
INSERT INTO ingredients (recipe,article,unit,value,comment) VALUES (1,2,4,50,"50g Zwiebeln");
INSERT INTO ingredients (recipe,article,unit,value,comment) VALUES (1,3,1,1,"1l Wasser");
INSERT INTO ingredients (recipe,article,unit,value,comment) VALUES (1,4,4,5,"5g Pfeffer");
INSERT INTO ingredients (recipe,article,unit,value,comment) VALUES (1,5,4,5,"5g Salz");
