-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Tue Sep 26 04:32:00 2017
-- 

;
BEGIN TRANSACTION;
--
-- Table: projects
--
CREATE TABLE projects (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  url_name text NOT NULL,
  url_name_fc text NOT NULL
);
CREATE UNIQUE INDEX projects_name ON projects (name);
CREATE UNIQUE INDEX projects_url_name ON projects (url_name);
CREATE UNIQUE INDEX projects_url_name_fc ON projects (url_name_fc);
--
-- Table: meals
--
CREATE TABLE meals (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  date date NOT NULL,
  name text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX meals_idx_project ON meals (project);
CREATE UNIQUE INDEX meals_project_date_name ON meals (project, date, name);
--
-- Table: purchase_lists
--
CREATE TABLE purchase_lists (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  name text NOT NULL,
  date date NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX purchase_lists_idx_project ON purchase_lists (project);
CREATE UNIQUE INDEX purchase_lists_project_name ON purchase_lists (project, name);
--
-- Table: recipes
--
CREATE TABLE recipes (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  name text NOT NULL,
  preparation text NOT NULL,
  description text NOT NULL,
  servings int NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX recipes_idx_project ON recipes (project);
CREATE UNIQUE INDEX recipes_project_name ON recipes (project, name);
--
-- Table: shop_sections
--
CREATE TABLE shop_sections (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  name text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX shop_sections_idx_project ON shop_sections (project);
CREATE UNIQUE INDEX shop_sections_project_name ON shop_sections (project, name);
--
-- Table: tag_groups
--
CREATE TABLE tag_groups (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  color int,
  name text NOT NULL,
  comment text NOT NULL DEFAULT '',
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX tag_groups_idx_project ON tag_groups (project);
CREATE UNIQUE INDEX tag_groups_project_name ON tag_groups (project, name);
--
-- Table: articles
--
CREATE TABLE articles (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  shop_section int,
  shelf_life_days int,
  preorder_servings int,
  preorder_workdays int,
  name text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (shop_section) REFERENCES shop_sections(id) ON DELETE CASCADE
);
CREATE INDEX articles_idx_project ON articles (project);
CREATE INDEX articles_idx_shop_section ON articles (shop_section);
CREATE UNIQUE INDEX articles_project_name ON articles (project, name);
--
-- Table: quantities
--
CREATE TABLE quantities (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  name text NOT NULL,
  default_unit int,
  FOREIGN KEY (default_unit) REFERENCES units(id),
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX quantities_idx_default_unit ON quantities (default_unit);
CREATE INDEX quantities_idx_project ON quantities (project);
CREATE UNIQUE INDEX quantities_project_name ON quantities (project, name);
--
-- Table: tags
--
CREATE TABLE tags (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  tag_group int,
  name text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_group) REFERENCES tag_groups(id) ON DELETE CASCADE
);
CREATE INDEX tags_idx_project ON tags (project);
CREATE INDEX tags_idx_tag_group ON tags (tag_group);
CREATE UNIQUE INDEX tags_project_name ON tags (project, name);
--
-- Table: units
--
CREATE TABLE units (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  quantity int NOT NULL,
  to_quantity_default real,
  space bool NOT NULL,
  short_name text NOT NULL,
  long_name text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (quantity) REFERENCES quantities(id) ON DELETE CASCADE
);
CREATE INDEX units_idx_project ON units (project);
CREATE INDEX units_idx_quantity ON units (quantity);
CREATE UNIQUE INDEX units_project_long_name ON units (project, long_name);
--
-- Table: dishes
--
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
  FOREIGN KEY (meal) REFERENCES meals(id) ON DELETE CASCADE,
  FOREIGN KEY (prepare_at_meal) REFERENCES meals(id) ON DELETE CASCADE,
  FOREIGN KEY (from_recipe) REFERENCES recipes(id) ON DELETE CASCADE
);
CREATE INDEX dishes_idx_meal ON dishes (meal);
CREATE INDEX dishes_idx_prepare_at_meal ON dishes (prepare_at_meal);
CREATE INDEX dishes_idx_from_recipe ON dishes (from_recipe);
--
-- Table: recipes_tags
--
CREATE TABLE recipes_tags (
  recipe int NOT NULL,
  tag int NOT NULL,
  PRIMARY KEY (recipe, tag),
  FOREIGN KEY (recipe) REFERENCES recipes(id) ON DELETE CASCADE,
  FOREIGN KEY (tag) REFERENCES tags(id) ON DELETE CASCADE
);
CREATE INDEX recipes_tags_idx_recipe ON recipes_tags (recipe);
CREATE INDEX recipes_tags_idx_tag ON recipes_tags (tag);
--
-- Table: articles_tags
--
CREATE TABLE articles_tags (
  article int NOT NULL,
  tag int NOT NULL,
  PRIMARY KEY (article, tag),
  FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE,
  FOREIGN KEY (tag) REFERENCES tags(id) ON DELETE CASCADE
);
CREATE INDEX articles_tags_idx_article ON articles_tags (article);
CREATE INDEX articles_tags_idx_tag ON articles_tags (tag);
--
-- Table: articles_units
--
CREATE TABLE articles_units (
  article int NOT NULL,
  unit int NOT NULL,
  PRIMARY KEY (article, unit),
  FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id) ON DELETE CASCADE
);
CREATE INDEX articles_units_idx_article ON articles_units (article);
CREATE INDEX articles_units_idx_unit ON articles_units (unit);
--
-- Table: dishes_tags
--
CREATE TABLE dishes_tags (
  dish int NOT NULL,
  tag int NOT NULL,
  PRIMARY KEY (dish, tag),
  FOREIGN KEY (dish) REFERENCES dishes(id) ON DELETE CASCADE,
  FOREIGN KEY (tag) REFERENCES tags(id) ON DELETE CASCADE
);
CREATE INDEX dishes_tags_idx_dish ON dishes_tags (dish);
CREATE INDEX dishes_tags_idx_tag ON dishes_tags (tag);
--
-- Table: items
--
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
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit) ON DELETE CASCADE,
  FOREIGN KEY (purchase_list) REFERENCES purchase_lists(id) ON DELETE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id) ON DELETE CASCADE
);
CREATE INDEX items_idx_article ON items (article);
CREATE INDEX items_idx_article_unit ON items (article, unit);
CREATE INDEX items_idx_purchase_list ON items (purchase_list);
CREATE INDEX items_idx_unit ON items (unit);
CREATE UNIQUE INDEX items_purchase_list_article_unit ON items (purchase_list, article, unit);
--
-- Table: recipe_ingredients
--
CREATE TABLE recipe_ingredients (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  recipe int NOT NULL,
  prepare bool NOT NULL,
  article int NOT NULL,
  unit int NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE,
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit) ON DELETE CASCADE,
  FOREIGN KEY (recipe) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id) ON DELETE CASCADE
);
CREATE INDEX recipe_ingredients_idx_article ON recipe_ingredients (article);
CREATE INDEX recipe_ingredients_idx_article_unit ON recipe_ingredients (article, unit);
CREATE INDEX recipe_ingredients_idx_recipe ON recipe_ingredients (recipe);
CREATE INDEX recipe_ingredients_idx_unit ON recipe_ingredients (unit);
--
-- Table: dish_ingredients
--
CREATE TABLE dish_ingredients (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  dish int NOT NULL,
  prepare bool NOT NULL,
  article int NOT NULL,
  unit int NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  item int,
  FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE,
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit) ON DELETE CASCADE,
  FOREIGN KEY (dish) REFERENCES dishes(id) ON DELETE CASCADE,
  FOREIGN KEY (item) REFERENCES items(id) ON DELETE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id) ON DELETE CASCADE
);
CREATE INDEX dish_ingredients_idx_article ON dish_ingredients (article);
CREATE INDEX dish_ingredients_idx_article_unit ON dish_ingredients (article, unit);
CREATE INDEX dish_ingredients_idx_dish ON dish_ingredients (dish);
CREATE INDEX dish_ingredients_idx_item ON dish_ingredients (item);
CREATE INDEX dish_ingredients_idx_unit ON dish_ingredients (unit);
COMMIT;
