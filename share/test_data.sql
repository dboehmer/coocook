-- SQL code in this file MUST run in SQLite.
-- SQL code in this file MUST run in PostgreSQL.
-- SQL code in this file SHOULD be compliant to the latest ANSI/ISO standard SQL.

INSERT INTO "users"
(id,       name,    name_fc, password_hash, display_name,                   admin_comment,               email_fc,    email_verified, token_hash, token_expires,           created) VALUES
( 1, 'john_doe', 'john_doe',        'KOHL',   'John Doe',       'test user from test SQL', 'john.doe@example.com', CURRENT_TIMESTAMP,       NULL,          NULL, CURRENT_TIMESTAMP),
( 2,    'other',    'other',       'other', 'Other User', 'other test user from test SQL',    'other@example.com', CURRENT_TIMESTAMP,       NULL,          NULL, CURRENT_TIMESTAMP);

-- password: P@ssw0rd
UPDATE "users" SET password_hash = '$argon2i$v=19$m=32768,t=3,p=1$Gwe2aqtW9TbCpSosuN0O6Q$ISAlqvQF0LJNjj1KMgkBcw' WHERE id = 1;

INSERT INTO "roles_users"
(        role, user_id) VALUES
('site_owner',       1);

INSERT INTO "organizations"
(id,       name,    name_fc, display_name, owner_id, description_md) VALUES
( 1, 'TestData', 'testdata',  'Test Data',        1, 'from test data');

INSERT INTO "organizations_users"
(organization_id, user_id, role) VALUES
(              1,       1, 'owner');

INSERT INTO "projects"
(id,            name,        url_name,     url_name_fc,      description, is_public, owner_id,           created, archived) VALUES
( 1,  'Test Project',  'Test-Project',  'test-project',  'Test Project.',      TRUE,        1, CURRENT_TIMESTAMP,     NULL),
( 2, 'Other Project', 'Other-Project', 'other-project', 'Other Project.',     FALSE,        1, CURRENT_TIMESTAMP,     NULL);

INSERT INTO "projects_users"
(project_id, user_id,     role) VALUES
(         1,       1,  'owner'),
(         1,       2, 'editor'),
(         2,       1,  'owner');

INSERT INTO "shop_sections"
(id, project_id,              name) VALUES
( 1,          1, 'bakery products'),
( 2,          1,   'milk products'),
( 9,          2,   'other product');

INSERT INTO "articles"
(id, project_id, shop_section_id, shelf_life_days, preorder_servings, preorder_workdays,            name, comment) VALUES
( 1,          1,               1,            NULL,              NULL,              NULL,         'flour',      ''),
( 2,          1,               1,            NULL,              NULL,              NULL,          'salt',      ''),
( 3,          1,            NULL,            NULL,              NULL,              NULL,         'water',      ''),
( 4,          1,               2,            NULL,              NULL,              NULL,        'cheese',      ''),
( 5,          1,            NULL,            NULL,              NULL,              NULL,          'love',      ''), -- has no unit
( 6,          2,               9,            NULL,              NULL,              NULL, 'other article',      '');

INSERT INTO "meals"
(id, project_id,        date,         name,                comment) VALUES
( 1,          1,'2000-01-01',  'breakfast','Best meal of the day!'),
( 2,          1,'2000-01-02',      'lunch',                     ''),
( 3,          1,'2000-01-03',     'dinner',                     ''),
( 9,          2,'2000-01-01', 'other meal',                     '');

INSERT INTO "quantities"
(id, project_id,       name, default_unit_id) VALUES
( 1,          1,     'Mass',            NULL),
( 2,          1,   'Volume',            NULL);

INSERT INTO "units"
(id, project_id, quantity_id, to_quantity_default, space,   short_name,    long_name) VALUES
( 1,          1,           1,               0.001, FALSE,          'g',      'grams'),
( 2,          1,           1,                 1.0, FALSE,         'kg',  'kilograms'),
( 3,          1,           2,                 1.0, FALSE,          'l',     'liters'),
( 4,          1,           1,                1000, FALSE,          't',       'tons'),
( 5,          1,           1,                NULL, FALSE,          'p',      'pinch'); -- no conversion, (in German: Prise)

UPDATE "quantities" SET default_unit_id = 2 WHERE id = 1; -- added later to pass FK check
UPDATE "quantities" SET default_unit_id = 3 WHERE id = 2;

INSERT INTO "articles_units"
(article_id, unit_id) VALUES
(         1,       1),
(         1,       2),
(         2,       1),
(         3,       3),
(         4,       1),
(         4,       2);

INSERT INTO "recipes"
(id, project_id,           name, preparation, description, servings) VALUES
( 1,          1,        'pizza',          '',          '',        4),
( 2,          2, 'rice pudding',          '',          '',       42);

INSERT INTO "recipe_ingredients"
(id, position, recipe_id, prepare, article_id, unit_id, value,             comment) VALUES
( 1,        3,         1,   FALSE,          2,       1,  15.0,                  ''),
( 2,        2,         1,   FALSE,          1,       2,   1.0,                  ''),
( 3,        1,         1,   FALSE,          3,       3,   0.5,                  ''),
( 4,        4,         1,   FALSE,          2,       1,  10.0, 'if you like salty'); -- 2nd ingredient with same article/unit


INSERT INTO "dishes"
(id, meal_id, from_recipe_id,         name, servings, prepare_at_meal_id,    preparation,                 description, comment) VALUES
( 1,       1,           NULL,   'pancakes',        4,               NULL,             '',   'Make them really sweet!',      ''),
( 2,       2,              1,      'pizza',        2,               NULL,             '',                          '',      ''),
( 3,       3,           NULL,      'bread',        4,                  2,  'Bake bread!',                          '',      '');

INSERT INTO "dish_ingredients"
(id, position, dish_id, prepare, article_id, unit_id,  value, comment, item_id) VALUES
( 1,        1,       1, FALSE,            1,       1,  500.0,      '',    NULL),
( 2,        2,       1, FALSE,            2,       1,    5.0,      '',    NULL),
( 3,        3,       1, FALSE,            3,       3,    0.5,      '',    NULL),
( 4,        1,       2, FALSE,            1,       2,    0.5,      '',    NULL),
( 5,        2,       2, FALSE,            3,       3,   0.25,      '',    NULL),
( 6,        3,       2, FALSE,            2,       1,   12.5,      '',    NULL),
( 7,        1,       3, FALSE,            1,       2,    1.0,      '',    NULL),
( 8,        2,       3, FALSE,            2,       1,   25.0,      '',    NULL),
( 9,        3,       3, FALSE,            3,       3,    1.0,      '',    NULL),
(10,        4,       3, FALSE,            4,       1,  500.0,      '',    NULL),
(11,        5,       3, FALSE,            1,       2,   12.5,      '',    NULL);

INSERT INTO "purchase_lists"
(id, project_id,         name,        date) VALUES
( 1,          1,'all at once','1999-12-31');

INSERT INTO "items"
(id, purchase_list_id, value, "offset", unit_id, article_id, purchased, comment) VALUES
( 1,                1,  1000,      0.0,       1,          1,     FALSE,      ''),
( 2,                1,  37.5,      0.0,       1,          2,     FALSE,      '');

UPDATE "dish_ingredients" SET item_id = 1 WHERE id IN (1,4);
UPDATE "dish_ingredients" SET item_id = 2 WHERE id IN (6,8);

INSERT INTO "tag_groups"
(id, project_id,    color,        name,    comment) VALUES
( 1,          1, 16711680, 'allergens', 'may harm'); -- 16711680 = 0xff0000 (red)

INSERT INTO "tags"
(id, project_id, tag_group_id,        name) VALUES
( 1,          1,            1,    'gluten'),
( 2,          1,            1,   'lactose'),
( 3,          1,         NULL, 'delicious');

INSERT INTO "articles_tags"
(article_id, tag_id) VALUES
(         1,      1),
(         4,      2);

INSERT INTO "recipes_tags"
(recipe_id, tag_id) VALUES
(        1,      3);

INSERT INTO "faqs"
(id, position, anchor,                                        question_md,                                                                    answer_md) VALUES
( 1,        2, 'foss', 'Is Coocook free and open-source software (FOSS)?',                                                                'Yes, it is.'),
( 2,        1, 'what',                                 'What is Coocook?', 'Coocook is a web application for collecting recipes and making food plans.');

INSERT INTO "terms"
(id,   valid_from,                                 content_md) VALUES
( 1, '1999-01-01',       'All your recipes are belong to us.'),
( 2, '2100-01-01', 'Just STEAL ALL THE COOKING INSTRUCTIONS!');

INSERT INTO "blacklist_usernames" 
(       "comment", "username_fc", "username_type") VALUES
( 'test_data.sql',   '*coocook*',      'wildcard'),
( 'test_data.sql',       'admin',     'cleartext');

INSERT INTO "blacklist_emails" 
(       "comment",                                     "email_fc", "email_type") VALUES
( 'test_data.sql', 'eH1bfAbKCiHJZDbMfIEX5v4EbQ/X3tyujJO/wUuOXfc=', 'sha256_b64'), -- somebody@example.com
( 'test_data.sql',                            '*@coocook.example',   'wildcard'),
( 'test_data.sql',                                '*@coocook.org',   'wildcard'),
( 'test_data.sql',                              '*@*.coocook.org',   'wildcard');
