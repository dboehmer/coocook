PRAGMA foreign_keys = ON;
-- password: P@ssw0rd
INSERT INTO 'users' VALUES(1,'john_doe','john_doe','$argon2i$v=19$m=32768,t=3,p=1$Gwe2aqtW9TbCpSosuN0O6Q$ISAlqvQF0LJNjj1KMgkBcw','John Doe','john.doe@example.com',DATETIME('now'),NULL,NULL);
INSERT INTO 'users' VALUES(2,'other','other','other','Other User','other@example.com',DATETIME('now'),NULL,NULL);
INSERT INTO 'roles_users' VALUES('site_admin',1);
INSERT INTO 'projects' VALUES(1,'Test','test','test','Test Project.',1,1);
INSERT INTO 'projects' VALUES(2,'Other Project','other-project','other-project','Other Project.',0,1);
INSERT INTO 'projects_users' VALUES(1,1,'owner');
INSERT INTO 'projects_users' VALUES(1,2,'editor');
INSERT INTO 'projects_users' VALUES(2,1,'owner');
INSERT INTO 'shop_sections' VALUES(1,1,'bakery products');
INSERT INTO 'shop_sections' VALUES(2,1,'milk products');
INSERT INTO 'shop_sections' VALUES(9,2,'other product');
INSERT INTO 'articles' VALUES(1,1,   1,NULL,NULL,NULL,'flour','');
INSERT INTO 'articles' VALUES(2,1,   1,NULL,NULL,NULL,'salt','');
INSERT INTO 'articles' VALUES(3,1,NULL,NULL,NULL,NULL,'water','');
INSERT INTO 'articles' VALUES(4,1,   2,NULL,NULL,NULL,'cheese','');
INSERT INTO 'articles' VALUES(5,1,NULL,NULL,NULL,NULL,'love',''); -- has no unit
INSERT INTO 'articles' VALUES(6,2,   9,NULL,NULL,NULL,'other article','');
INSERT INTO 'meals' VALUES(1,1,'2000-01-01','breakfast','Best meal of the day!');
INSERT INTO 'meals' VALUES(2,1,'2000-01-02','lunch','');
INSERT INTO 'meals' VALUES(3,1,'2000-01-03','dinner','');
INSERT INTO 'meals' VALUES(9,2,'2000-01-01','other meal','');
INSERT INTO 'quantities' VALUES(1,1,'Mass',NULL);
INSERT INTO 'quantities' VALUES(2,1,'Volume',NULL);
INSERT INTO 'units' VALUES(1,1,1,0.001,0,'g','grams');
INSERT INTO 'units' VALUES(2,1,1,1.0,0,'kg','kilograms');
INSERT INTO 'units' VALUES(3,1,2,1.0,0,'l','liters');
INSERT INTO 'units' VALUES(4,1,1,1000,0,'t','tons');
INSERT INTO 'units' VALUES(5,1,1,NULL,0,'p','pinch'); -- no conversion, (in German: Prise)
UPDATE 'quantities' SET default_unit = 2 WHERE id = 1; -- added later to pass FK check
UPDATE 'quantities' SET default_unit = 3 WHERE id = 2;
INSERT INTO 'articles_units' VALUES(1,1);
INSERT INTO 'articles_units' VALUES(1,2);
INSERT INTO 'articles_units' VALUES(2,1);
INSERT INTO 'articles_units' VALUES(3,3);
INSERT INTO 'articles_units' VALUES(4,1);
INSERT INTO 'articles_units' VALUES(4,2);
INSERT INTO 'recipes' VALUES(1,1,'pizza','','',4);
INSERT INTO 'recipe_ingredients' VALUES(1,1,1,0,1,2,1.0,'');
INSERT INTO 'recipe_ingredients' VALUES(2,2,1,0,3,3,0.5,'');
INSERT INTO 'recipe_ingredients' VALUES(3,3,1,0,2,1,25.0,'');
INSERT INTO 'dishes' VALUES(1,1,NULL,'pancakes',4,NULL,'','Make them really sweet!','');
INSERT INTO 'dishes' VALUES(2,2,1,'pizza',2,NULL,'','','');
INSERT INTO 'dishes' VALUES(3,3,NULL,'bread',4,2,'Bake bread!','','');
INSERT INTO 'dish_ingredients' VALUES(1,1,1,0,1,1,500.0,'',NULL);
INSERT INTO 'dish_ingredients' VALUES(2,2,1,0,2,1,5.0,'',NULL);
INSERT INTO 'dish_ingredients' VALUES(3,3,1,0,3,3,0.5,'',NULL);
INSERT INTO 'dish_ingredients' VALUES(4,1,2,0,1,2,0.5,'',NULL);
INSERT INTO 'dish_ingredients' VALUES(5,2,2,0,3,3,0.25,'',NULL);
INSERT INTO 'dish_ingredients' VALUES(6,3,2,0,2,1,12.5,'',NULL);
INSERT INTO 'dish_ingredients' VALUES(7,1,3,1,1,2,1.0,'',NULL);
INSERT INTO 'dish_ingredients' VALUES(8,2,3,1,2,1,25.0,'',NULL);
INSERT INTO 'dish_ingredients' VALUES(9,3,3,1,3,3,1.0,'',NULL);
INSERT INTO 'dish_ingredients' VALUES(10,4,3,0,4,1,500.0,'',NULL);
INSERT INTO 'purchase_lists' VALUES(1,1,'all at once','1999-12-31');

INSERT INTO 'items' VALUES(1,1,1000,0.0,1,1,0,'');
UPDATE 'dish_ingredients' SET 'item' = 1 WHERE id IN (1,4);

INSERT INTO 'items' VALUES(2,1,37.5,0.0,1,2,0,'');
UPDATE 'dish_ingredients' SET 'item' = 2 WHERE id IN (6,8);

INSERT INTO 'tag_groups' VALUES(1,1,0xff0000,'allergens','may harm');
INSERT INTO 'tags' VALUES(1,1,1,'gluten');
INSERT INTO 'tags' VALUES(2,1,1,'lactose');
INSERT INTO 'tags' VALUES(3,1,NULL,'delicious');
INSERT INTO 'articles_tags' VALUES(1,1);
INSERT INTO 'articles_tags' VALUES(4,2);
INSERT INTO 'recipes_tags' VALUES(1,3);

INSERT INTO 'faqs' VALUES(1,2,'foss','Is Coocook free and open-source software (FOSS)?','Yes, it is.');
INSERT INTO 'faqs' VALUES(2,1,'what','What is Coocook?','Coocook is a web application for collecting recipes and making food plans.');
