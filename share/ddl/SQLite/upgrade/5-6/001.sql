-- Convert schema 'share/ddl/_source/deploy/5/001-auto.yml' to 'share/ddl/_source/deploy/6/001-auto.yml':;

BEGIN;

-- ABSTRACT: add 'project' column to many tables missing it

-- not strictly necessary to use same project for all changed tables
-- but makes debugging easier
CREATE TEMPORARY TABLE random_project ( id INTEGER );

INSERT INTO random_project SELECT id FROM projects LIMIT 1;

CREATE TEMPORARY TABLE articles_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  shop_section int,
  shelf_life_days int,
  preorder_servings int,
  preorder_workdays int,
  name text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id),
  FOREIGN KEY (shop_section) REFERENCES shop_sections(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO articles_temp_alter SELECT id, (SELECT id FROM random_project), shop_section, shelf_life_days, preorder_servings, preorder_workdays, name, comment FROM articles;

DROP TABLE articles;

CREATE TABLE articles (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  shop_section int,
  shelf_life_days int,
  preorder_servings int,
  preorder_workdays int,
  name text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id),
  FOREIGN KEY (shop_section) REFERENCES shop_sections(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX articles_idx_project02 ON articles (project);

CREATE INDEX articles_idx_shop_section02 ON articles (shop_section);

CREATE UNIQUE INDEX articles_project_name02 ON articles (project, name);

INSERT INTO articles SELECT id, project, shop_section, shelf_life_days, preorder_servings, preorder_workdays, name, comment FROM articles_temp_alter;

DROP TABLE articles_temp_alter;

CREATE TEMPORARY TABLE articles_tags_temp_alter (
  article int NOT NULL,
  tag int NOT NULL,
  PRIMARY KEY (article, tag),
  FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (tag) REFERENCES tags(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO articles_tags_temp_alter( article, tag) SELECT article, tag FROM articles_tags;

DROP TABLE articles_tags;

CREATE TABLE articles_tags (
  article int NOT NULL,
  tag int NOT NULL,
  PRIMARY KEY (article, tag),
  FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (tag) REFERENCES tags(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX articles_tags_idx_article02 ON articles_tags (article);

CREATE INDEX articles_tags_idx_tag02 ON articles_tags (tag);

INSERT INTO articles_tags SELECT article, tag FROM articles_tags_temp_alter;

DROP TABLE articles_tags_temp_alter;

CREATE TEMPORARY TABLE articles_units_temp_alter (
  article int NOT NULL,
  unit int NOT NULL,
  PRIMARY KEY (article, unit),
  FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO articles_units_temp_alter( article, unit) SELECT article, unit FROM articles_units;

DROP TABLE articles_units;

CREATE TABLE articles_units (
  article int NOT NULL,
  unit int NOT NULL,
  PRIMARY KEY (article, unit),
  FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX articles_units_idx_article02 ON articles_units (article);

CREATE INDEX articles_units_idx_unit02 ON articles_units (unit);

INSERT INTO articles_units SELECT article, unit FROM articles_units_temp_alter;

DROP TABLE articles_units_temp_alter;

CREATE TEMPORARY TABLE dish_ingredients_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  dish int NOT NULL,
  prepare bool NOT NULL,
  article int NOT NULL,
  unit int NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (dish) REFERENCES dishes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id)
);

INSERT INTO dish_ingredients_temp_alter( id, position, dish, prepare, article, unit, value, comment) SELECT id, position, dish, prepare, article, unit, value, comment FROM dish_ingredients;

DROP TABLE dish_ingredients;

CREATE TABLE dish_ingredients (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  dish int NOT NULL,
  prepare bool NOT NULL,
  article int NOT NULL,
  unit int NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (dish) REFERENCES dishes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id)
);

CREATE INDEX dish_ingredients_idx_article02 ON dish_ingredients (article);

CREATE INDEX dish_ingredients_idx_articl00 ON dish_ingredients (article, unit);

CREATE INDEX dish_ingredients_idx_dish02 ON dish_ingredients (dish);

CREATE INDEX dish_ingredients_idx_unit02 ON dish_ingredients (unit);

INSERT INTO dish_ingredients SELECT id, position, dish, prepare, article, unit, value, comment FROM dish_ingredients_temp_alter;

DROP TABLE dish_ingredients_temp_alter;

CREATE TEMPORARY TABLE dishes_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  meal int NOT NULL,
  from_recipe int,
  name text NOT NULL,
  servings int NOT NULL,
  prepare_at_meal int,
  preparation text NOT NULL,
  description text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (meal) REFERENCES meals(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (prepare_at_meal) REFERENCES meals(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (from_recipe) REFERENCES recipes(id)
);

INSERT INTO dishes_temp_alter( id, meal, from_recipe, name, servings, prepare_at_meal, preparation, description, comment) SELECT id, meal, from_recipe, name, servings, prepare_at_meal, preparation, description, comment FROM dishes;

DROP TABLE dishes;

CREATE TABLE dishes (
  id INTEGER PRIMARY KEY NOT NULL,
  meal int NOT NULL,
  from_recipe int,
  name text NOT NULL,
  servings int NOT NULL,
  prepare_at_meal int,
  preparation text NOT NULL,
  description text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (meal) REFERENCES meals(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (prepare_at_meal) REFERENCES meals(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (from_recipe) REFERENCES recipes(id)
);

CREATE INDEX dishes_idx_meal02 ON dishes (meal);

CREATE INDEX dishes_idx_prepare_at_meal02 ON dishes (prepare_at_meal);

CREATE INDEX dishes_idx_from_recipe02 ON dishes (from_recipe);

INSERT INTO dishes SELECT id, meal, from_recipe, name, servings, prepare_at_meal, preparation, description, comment FROM dishes_temp_alter;

DROP TABLE dishes_temp_alter;

CREATE TEMPORARY TABLE dishes_tags_temp_alter (
  dish int NOT NULL,
  tag int NOT NULL,
  PRIMARY KEY (dish, tag),
  FOREIGN KEY (dish) REFERENCES dishes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (tag) REFERENCES tags(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO dishes_tags_temp_alter( dish, tag) SELECT dish, tag FROM dishes_tags;

DROP TABLE dishes_tags;

CREATE TABLE dishes_tags (
  dish int NOT NULL,
  tag int NOT NULL,
  PRIMARY KEY (dish, tag),
  FOREIGN KEY (dish) REFERENCES dishes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (tag) REFERENCES tags(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX dishes_tags_idx_dish02 ON dishes_tags (dish);

CREATE INDEX dishes_tags_idx_tag02 ON dishes_tags (tag);

INSERT INTO dishes_tags SELECT dish, tag FROM dishes_tags_temp_alter;

DROP TABLE dishes_tags_temp_alter;

CREATE TEMPORARY TABLE ingredients_items_temp_alter (
  ingredient int NOT NULL,
  item int NOT NULL,
  PRIMARY KEY (ingredient, item),
  FOREIGN KEY (ingredient) REFERENCES dish_ingredients(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (item) REFERENCES items(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO ingredients_items_temp_alter( ingredient, item) SELECT ingredient, item FROM ingredients_items;

DROP TABLE ingredients_items;

CREATE TABLE ingredients_items (
  ingredient int NOT NULL,
  item int NOT NULL,
  PRIMARY KEY (ingredient, item),
  FOREIGN KEY (ingredient) REFERENCES dish_ingredients(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (item) REFERENCES items(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX ingredients_items_idx_ingre00 ON ingredients_items (ingredient);

CREATE INDEX ingredients_items_idx_item02 ON ingredients_items (item);

INSERT INTO ingredients_items SELECT ingredient, item FROM ingredients_items_temp_alter;

DROP TABLE ingredients_items_temp_alter;

CREATE TEMPORARY TABLE items_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  purchase_list int NOT NULL,
  value real NOT NULL,
  offset real NOT NULL DEFAULT 0,
  unit int NOT NULL,
  article int NOT NULL,
  purchased bool NOT NULL DEFAULT '0',
  comment text NOT NULL,
  FOREIGN KEY (article) REFERENCES articles(id),
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (purchase_list) REFERENCES purchase_lists(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id)
);

INSERT INTO items_temp_alter( id, purchase_list, value, offset, unit, article, purchased, comment) SELECT id, purchase_list, value, offset, unit, article, purchased, comment FROM items;

DROP TABLE items;

CREATE TABLE items (
  id INTEGER PRIMARY KEY NOT NULL,
  purchase_list int NOT NULL,
  value real NOT NULL,
  offset real NOT NULL DEFAULT 0,
  unit int NOT NULL,
  article int NOT NULL,
  purchased bool NOT NULL DEFAULT '0',
  comment text NOT NULL,
  FOREIGN KEY (article) REFERENCES articles(id),
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (purchase_list) REFERENCES purchase_lists(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id)
);

CREATE INDEX items_idx_article02 ON items (article);

CREATE INDEX items_idx_article_unit02 ON items (article, unit);

CREATE INDEX items_idx_purchase_list02 ON items (purchase_list);

CREATE INDEX items_idx_unit02 ON items (unit);

CREATE UNIQUE INDEX items_purchase_list_article00 ON items (purchase_list, article, unit);

INSERT INTO items SELECT id, purchase_list, value, offset, unit, article, purchased, comment FROM items_temp_alter;

DROP TABLE items_temp_alter;

CREATE TEMPORARY TABLE meals_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  date date NOT NULL,
  name text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO meals_temp_alter( id, project, date, name, comment) SELECT id, project, date, name, comment FROM meals;

DROP TABLE meals;

CREATE TABLE meals (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  date date NOT NULL,
  name text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX meals_idx_project02 ON meals (project);

CREATE UNIQUE INDEX meals_project_date_name02 ON meals (project, date, name);

INSERT INTO meals SELECT id, project, date, name, comment FROM meals_temp_alter;

DROP TABLE meals_temp_alter;

CREATE TEMPORARY TABLE projects_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  url_name text NOT NULL,
  url_name_fc text NOT NULL
);

INSERT INTO projects_temp_alter( id, name, url_name, url_name_fc) SELECT id, name, url_name, url_name_fc FROM projects;

DROP TABLE projects;

CREATE TABLE projects (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  url_name text NOT NULL,
  url_name_fc text NOT NULL
);

CREATE UNIQUE INDEX projects_name02 ON projects (name);

CREATE UNIQUE INDEX projects_url_name02 ON projects (url_name);

CREATE UNIQUE INDEX projects_url_name_fc02 ON projects (url_name_fc);

INSERT INTO projects SELECT id, name, url_name, url_name_fc FROM projects_temp_alter;

DROP TABLE projects_temp_alter;

CREATE TEMPORARY TABLE purchase_lists_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  name text NOT NULL,
  date date NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO purchase_lists_temp_alter( id, project, name, date) SELECT id, project, name, date FROM purchase_lists;

DROP TABLE purchase_lists;

CREATE TABLE purchase_lists (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  name text NOT NULL,
  date date NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX purchase_lists_idx_project02 ON purchase_lists (project);

CREATE UNIQUE INDEX purchase_lists_project_name02 ON purchase_lists (project, name);

INSERT INTO purchase_lists SELECT id, project, name, date FROM purchase_lists_temp_alter;

DROP TABLE purchase_lists_temp_alter;

CREATE TEMPORARY TABLE quantities_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  name text NOT NULL,
  default_unit int,
  FOREIGN KEY (default_unit) REFERENCES units(id),
  FOREIGN KEY (project) REFERENCES projects(id)
);

INSERT INTO quantities_temp_alter SELECT id, (SELECT id FROM random_project), name, default_unit FROM quantities;

DROP TABLE quantities;

CREATE TABLE quantities (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  name text NOT NULL,
  default_unit int,
  FOREIGN KEY (default_unit) REFERENCES units(id),
  FOREIGN KEY (project) REFERENCES projects(id)
);

CREATE INDEX quantities_idx_default_unit02 ON quantities (default_unit);

CREATE INDEX quantities_idx_project02 ON quantities (project);

CREATE UNIQUE INDEX quantities_project_name02 ON quantities (project, name);

INSERT INTO quantities SELECT id, project, name, default_unit FROM quantities_temp_alter;

DROP TABLE quantities_temp_alter;

CREATE TEMPORARY TABLE recipe_ingredients_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  recipe int NOT NULL,
  prepare bool NOT NULL,
  article int NOT NULL,
  unit int NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (recipe) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id)
);

INSERT INTO recipe_ingredients_temp_alter( id, position, recipe, prepare, article, unit, value, comment) SELECT id, position, recipe, prepare, article, unit, value, comment FROM recipe_ingredients;

DROP TABLE recipe_ingredients;

CREATE TABLE recipe_ingredients (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  recipe int NOT NULL,
  prepare bool NOT NULL,
  article int NOT NULL,
  unit int NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (recipe) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id)
);

CREATE INDEX recipe_ingredients_idx_arti00 ON recipe_ingredients (article);

CREATE INDEX recipe_ingredients_idx_arti01 ON recipe_ingredients (article, unit);

CREATE INDEX recipe_ingredients_idx_reci00 ON recipe_ingredients (recipe);

CREATE INDEX recipe_ingredients_idx_unit02 ON recipe_ingredients (unit);

INSERT INTO recipe_ingredients SELECT id, position, recipe, prepare, article, unit, value, comment FROM recipe_ingredients_temp_alter;

DROP TABLE recipe_ingredients_temp_alter;

CREATE TEMPORARY TABLE recipes_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  name text NOT NULL,
  preparation text NOT NULL,
  description text NOT NULL,
  servings int NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id)
);

INSERT INTO recipes_temp_alter SELECT id, (SELECT id FROM random_project), name, preparation, description, servings FROM recipes;

DROP TABLE recipes;

CREATE TABLE recipes (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  name text NOT NULL,
  preparation text NOT NULL,
  description text NOT NULL,
  servings int NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id)
);

CREATE INDEX recipes_idx_project02 ON recipes (project);

CREATE UNIQUE INDEX recipes_project_name02 ON recipes (project, name);

INSERT INTO recipes SELECT id, project, name, preparation, description, servings FROM recipes_temp_alter;

DROP TABLE recipes_temp_alter;

CREATE TEMPORARY TABLE recipes_tags_temp_alter (
  recipe int NOT NULL,
  tag int NOT NULL,
  PRIMARY KEY (recipe, tag),
  FOREIGN KEY (recipe) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (tag) REFERENCES tags(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO recipes_tags_temp_alter( recipe, tag) SELECT recipe, tag FROM recipes_tags;

DROP TABLE recipes_tags;

CREATE TABLE recipes_tags (
  recipe int NOT NULL,
  tag int NOT NULL,
  PRIMARY KEY (recipe, tag),
  FOREIGN KEY (recipe) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (tag) REFERENCES tags(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX recipes_tags_idx_recipe02 ON recipes_tags (recipe);

CREATE INDEX recipes_tags_idx_tag02 ON recipes_tags (tag);

INSERT INTO recipes_tags SELECT recipe, tag FROM recipes_tags_temp_alter;

DROP TABLE recipes_tags_temp_alter;

CREATE TEMPORARY TABLE shop_sections_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  name text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id)
);

INSERT INTO shop_sections_temp_alter SELECT id, (SELECT id FROM random_project), name FROM shop_sections;

DROP TABLE shop_sections;

CREATE TABLE shop_sections (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  name text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id)
);

CREATE INDEX shop_sections_idx_project02 ON shop_sections (project);

CREATE UNIQUE INDEX shop_sections_project_name02 ON shop_sections (project, name);

INSERT INTO shop_sections SELECT id, project, name FROM shop_sections_temp_alter;

DROP TABLE shop_sections_temp_alter;

CREATE TEMPORARY TABLE tag_groups_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  color int,
  name text NOT NULL,
  comment text NOT NULL DEFAULT '',
  FOREIGN KEY (project) REFERENCES projects(id)
);

INSERT INTO tag_groups_temp_alter SELECT id, (SELECT id FROM random_project), color, name, comment FROM tag_groups;

DROP TABLE tag_groups;

CREATE TABLE tag_groups (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  color int,
  name text NOT NULL,
  comment text NOT NULL DEFAULT '',
  FOREIGN KEY (project) REFERENCES projects(id)
);

CREATE INDEX tag_groups_idx_project02 ON tag_groups (project);

CREATE UNIQUE INDEX tag_groups_project_name02 ON tag_groups (project, name);

INSERT INTO tag_groups SELECT id, project, color, name, comment FROM tag_groups_temp_alter;

DROP TABLE tag_groups_temp_alter;

CREATE TEMPORARY TABLE tags_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  tag_group int,
  name text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id),
  FOREIGN KEY (tag_group) REFERENCES tag_groups(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO tags_temp_alter SELECT id, (SELECT id FROM random_project), tag_group, name FROM tags;

DROP TABLE tags;

CREATE TABLE tags (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  tag_group int,
  name text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id),
  FOREIGN KEY (tag_group) REFERENCES tag_groups(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX tags_idx_project02 ON tags (project);

CREATE INDEX tags_idx_tag_group02 ON tags (tag_group);

CREATE UNIQUE INDEX tags_project_name02 ON tags (project, name);

INSERT INTO tags SELECT id, project, tag_group, name FROM tags_temp_alter;

DROP TABLE tags_temp_alter;

CREATE TEMPORARY TABLE units_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  quantity int NOT NULL,
  to_quantity_default real,
  space bool NOT NULL,
  short_name text NOT NULL,
  long_name text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id),
  FOREIGN KEY (quantity) REFERENCES quantities(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO units_temp_alter SELECT id, (SELECT id FROM random_project), quantity, to_quantity_default, space, short_name, long_name FROM units;

DROP TABLE units;

CREATE TABLE units (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  quantity int NOT NULL,
  to_quantity_default real,
  space bool NOT NULL,
  short_name text NOT NULL,
  long_name text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id),
  FOREIGN KEY (quantity) REFERENCES quantities(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX units_idx_project02 ON units (project);

CREATE INDEX units_idx_quantity02 ON units (quantity);

CREATE UNIQUE INDEX units_project_long_name02 ON units (project, long_name);

INSERT INTO units SELECT id, project, quantity, to_quantity_default, space, short_name, long_name FROM units_temp_alter;

DROP TABLE units_temp_alter;

COMMIT;
