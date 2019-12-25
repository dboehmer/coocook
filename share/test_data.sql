PRAGMA foreign_keys = ON;
-- password: P@ssw0rd
INSERT INTO 'users'
(id,       name,    name_fc,                                                                 password_hash, display_name,                   admin_comment,                  email,    email_verified, token_hash, token_expires,           created) VALUES
( 1, 'john_doe', 'john_doe', '$argon2i$v=19$m=32768,t=3,p=1$Gwe2aqtW9TbCpSosuN0O6Q$ISAlqvQF0LJNjj1KMgkBcw',   'John Doe',       'test user from test SQL', 'john.doe@example.com', CURRENT_TIMESTAMP,       NULL,          NULL, CURRENT_TIMESTAMP),
( 2,    'other',    'other',                                                                       'other', 'Other User', 'other test user from test SQL',    'other@example.com', CURRENT_TIMESTAMP,       NULL,          NULL, CURRENT_TIMESTAMP);

INSERT INTO 'roles_users'
(        role, user) VALUES
('site_owner',    1);

INSERT INTO 'projects'
(id,            name,        url_name,     url_name_fc,      description, is_public, owner,           created, archived) VALUES
( 1,          'Test',          'Test',          'test',  'Test Project.',         1,     1, CURRENT_TIMESTAMP,     NULL),
( 2, 'Other Project', 'Other-project', 'other-project', 'Other Project.',         0,     1, CURRENT_TIMESTAMP,     NULL);

INSERT INTO 'projects_users'
(project, user,     role) VALUES
(      1,    1,  'owner'),
(      1,    2, 'editor'),
(      2,    1,  'owner');

INSERT INTO 'shop_sections'
(id, project,              name) VALUES
( 1,       1, 'bakery products'),
( 2,       1,   'milk products'),
( 9,       2,   'other product');

INSERT INTO 'articles'
(id, project, shop_section, shelf_life_days, preorder_servings, preorder_workdays,            name, comment) VALUES
( 1,       1,            1, 	       NULL,              NULL,              NULL,         'flour',      ''),
( 2,       1,            1,            NULL,              NULL,              NULL,          'salt',      ''),
( 3,       1,         NULL,            NULL,              NULL,              NULL,         'water',      ''),
( 4,       1,            2,            NULL,		  NULL,		     NULL,        'cheese',	 ''),
( 5,       1,         NULL,            NULL,		  NULL,		     NULL,          'love',	 ''), -- has no unit
( 6,       2,            9,            NULL,		  NULL,		     NULL, 'other article',	 '');

INSERT INTO 'meals'
(id, project,        date,         name,                comment) VALUES
( 1,       1,'2000-01-01',  'breakfast','Best meal of the day!'),
( 2,       1,'2000-01-02',      'lunch',                     ''),
( 3,       1,'2000-01-03',     'dinner',                     ''),
( 9,       2,'2000-01-01', 'other meal',                     '');

INSERT INTO 'quantities'
(id, project,       name, default_unit) VALUES
( 1,       1,     'Mass',         NULL),
( 2,       1,   'Volume',         NULL);

INSERT INTO 'units'
(id, project, quantity, to_quantity_default, space,   short_name,    long_name) VALUES
( 1,       1,        1,               0.001,     0,          'g',      'grams'),
( 2,       1,        1,                 1.0,     0,         'kg',  'kilograms'),
( 3,       1,        2,                 1.0,     0,          'l',     'liters'),
( 4,       1,        1,                1000,     0,          't',       'tons'),
( 5,       1,        1,                NULL,     0,          'p',      'pinch'); -- no conversion, (in German: Prise)

UPDATE 'quantities' SET default_unit = 2 WHERE id = 1; -- added later to pass FK check
UPDATE 'quantities' SET default_unit = 3 WHERE id = 2;

INSERT INTO 'articles_units'
(article, unit) VALUES
(      1,    1),
(      1,    2),
(      2,    1),
(      3,    3),
(      4,    1),
(      4,    2);

INSERT INTO 'recipes'
(id, project,     name, preparation, description, servings) VALUES
( 1,       1,  'pizza',          '',          '',        4);

INSERT INTO 'recipe_ingredients'
(id, position, recipe, prepare, article, unit, value, comment) VALUES
( 1,        1,      1,       0,       1,    2,   1.0,      ''),
( 2,        2,      1,       0,       3,    3,   0.5,      ''),
( 3,        3,      1,       0,       2,    1,  25.0,      '');

INSERT INTO 'dishes'
(id, meal, from_recipe,         name, servings, prepare_at_meal,    preparation,                 description, comment) VALUES
( 1,    1,        NULL,   'pancakes',        4,            NULL,             '',   'Make them really sweet!',      ''),
( 2,    2,           1,      'pizza',        2,            NULL,             '',                          '',      ''),
( 3,    3,        NULL,      'bread',        4,               2,  'Bake bread!',                          '',      '');

INSERT INTO 'dish_ingredients'
(id, position, dish, prepare, article, unit,  value, comment, item) VALUES
( 1,        1,    1,       0,       1,    1,  500.0,      '', NULL),
( 2,        2,    1,       0,       2,    1,    5.0,      '', NULL),
( 3,        3,    1,       0,       3,    3,    0.5,      '', NULL),
( 4,        1,    2,       0,       1,    2,    0.5,      '', NULL),
( 5,        2,    2,       0,       3,    3,   0.25,      '', NULL),
( 6,        3,    2,       0,       2,    1,   12.5,      '', NULL),
( 7,        1,    3,       1,       1,    2,    1.0,      '', NULL),
( 8,        2,    3,       1,       2,    1,   25.0,      '', NULL),
( 9,        3,    3,       1,       3,    3,    1.0,      '', NULL),
(10,        4,    3,       0,       4,    1,  500.0,      '', NULL);

INSERT INTO 'purchase_lists'
(id, project,         name,        date) VALUES
( 1,       1,'all at once','1999-12-31');

INSERT INTO 'items'
(id, purchase_list, value, offset, unit, article, purchased, comment) VALUES
( 1,             1,  1000,    0.0,    1,       1,         0,      ''),
( 2,   		 1,  37.5,    0.0,    1,       2,	  0,	  '');

UPDATE 'dish_ingredients' SET 'item' = 1 WHERE id IN (1,4);
UPDATE 'dish_ingredients' SET 'item' = 2 WHERE id IN (6,8);

INSERT INTO 'tag_groups'
(id, project,    color,        name,    comment) VALUES
( 1,       1, 0xff0000, 'allergens', 'may harm');

INSERT INTO 'tags'
(id, project, tag_group,        name) VALUES
( 1, 	   1,         1,    'gluten'),
( 2,	   1,	      1,   'lactose'),
( 3,	   1,	   NULL, 'delicious');

INSERT INTO 'articles_tags'
(article, tag) VALUES
(      1,   1),
(      4,   2);

INSERT INTO 'recipes_tags'
(recipe, tag) VALUES
(     1,   3);

INSERT INTO 'faqs'
(id, position, anchor,                                        question_md,                                                                    answer_md) VALUES
( 1,        2, 'foss', 'Is Coocook free and open-source software (FOSS)?',                                                                'Yes, it is.'),
( 2,        1, 'what',                                 'What is Coocook?', 'Coocook is a web application for collecting recipes and making food plans.');

INSERT INTO 'terms'
(id,   valid_from,                                 content_md) VALUES
( 1, '1999-01-01',       'All your recipes are belong to us.'),
( 2, '2100-01-01', 'Just STEAL ALL THE COOKING INSTRUCTIONS!');
