BEGIN;

-- ABSTRACT: recreate some tables to fix "DELETE CASCADE"-clauses

-- do NOT cascade rename into referencing PKs in SQLite >=3.25.0
-- see https://www.sqlite.org/lang_altertable.html
PRAGMA legacy_alter_table = 1;

--
-- Table: articles
--
ALTER TABLE articles RENAME TO old_articles;

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
  FOREIGN KEY (shop_section) REFERENCES shop_sections(id)
);
CREATE INDEX articles_idx_project ON articles (project);
CREATE INDEX articles_idx_shop_section ON articles (shop_section);
CREATE UNIQUE INDEX articles_project_name ON articles (project, name);

INSERT INTO articles SELECT * FROM old_articles;

DROP TABLE old_articles;


--
-- Table: articles_tags
--
ALTER TABLE articles_tags RENAME TO old_articles_tags;

CREATE TABLE articles_tags (
  article int NOT NULL,
  tag int NOT NULL,
  PRIMARY KEY (article, tag),
  FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE,
  FOREIGN KEY (tag) REFERENCES tags(id) ON DELETE CASCADE
);
CREATE INDEX articles_tags_idx_article ON articles_tags (article);
CREATE INDEX articles_tags_idx_tag ON articles_tags (tag);

INSERT INTO articles_tags SELECT * FROM old_articles_tags;

DROP TABLE old_articles_tags;


--
-- Table: articles_units
--
ALTER TABLE articles_units RENAME TO old_articles_units;

CREATE TABLE articles_units (
  article int NOT NULL,
  unit int NOT NULL,
  PRIMARY KEY (article, unit),
  FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id)
);
CREATE INDEX articles_units_idx_article ON articles_units (article);
CREATE INDEX articles_units_idx_unit ON articles_units (unit);

INSERT INTO articles_units SELECT * FROM old_articles_units;

DROP TABLE old_articles_units;


--
-- Table: dishes
--
ALTER TABLE dishes RENAME TO old_dishes;

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
  FOREIGN KEY (prepare_at_meal) REFERENCES meals(id),
  FOREIGN KEY (from_recipe) REFERENCES recipes(id)
);
CREATE INDEX dishes_idx_meal ON dishes (meal);
CREATE INDEX dishes_idx_prepare_at_meal ON dishes (prepare_at_meal);
CREATE INDEX dishes_idx_from_recipe ON dishes (from_recipe);

INSERT INTO dishes SELECT * FROM old_dishes;

DROP TABLE old_dishes;


--
-- Table: dishes_tags
--
ALTER TABLE dishes_tags RENAME TO old_dishes_tags;

CREATE TABLE dishes_tags (
  dish int NOT NULL,
  tag int NOT NULL,
  PRIMARY KEY (dish, tag),
  FOREIGN KEY (dish) REFERENCES dishes(id) ON DELETE CASCADE,
  FOREIGN KEY (tag) REFERENCES tags(id) ON DELETE CASCADE
);
CREATE INDEX dishes_tags_idx_dish ON dishes_tags (dish);
CREATE INDEX dishes_tags_idx_tag ON dishes_tags (tag);

INSERT INTO dishes_tags SELECT * FROM old_dishes_tags;

DROP TABLE old_dishes_tags;


--
-- Table: dish_ingredients
--
ALTER TABLE dish_ingredients RENAME TO old_dish_ingredients;

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
  FOREIGN KEY (article) REFERENCES articles(id),
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit),
  FOREIGN KEY (dish) REFERENCES dishes(id) ON DELETE CASCADE,
  FOREIGN KEY (item) REFERENCES items(id) ON DELETE SET NULL,
  FOREIGN KEY (unit) REFERENCES units(id)
);
CREATE INDEX dish_ingredients_idx_article ON dish_ingredients (article);
CREATE INDEX dish_ingredients_idx_article_unit ON dish_ingredients (article, unit);
CREATE INDEX dish_ingredients_idx_dish ON dish_ingredients (dish);
CREATE INDEX dish_ingredients_idx_item ON dish_ingredients (item);
CREATE INDEX dish_ingredients_idx_unit ON dish_ingredients (unit);
COMMIT;

INSERT INTO dish_ingredients SELECT * FROM old_dish_ingredients;

DROP TABLE old_dish_ingredients;


--
-- Table: items
--
ALTER TABLE items RENAME TO old_items;

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
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit),
  FOREIGN KEY (purchase_list) REFERENCES purchase_lists(id) ON DELETE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id)
);
CREATE INDEX items_idx_article ON items (article);
CREATE INDEX items_idx_article_unit ON items (article, unit);
CREATE INDEX items_idx_purchase_list ON items (purchase_list);
CREATE INDEX items_idx_unit ON items (unit);
CREATE UNIQUE INDEX items_purchase_list_article_unit ON items (purchase_list, article, unit);

INSERT INTO items SELECT * FROM old_items;

DROP TABLE old_items;


--
-- Table: meals
--
ALTER TABLE meals RENAME TO old_meals;

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

INSERT INTO meals SELECT * FROM old_meals;

DROP TABLE old_meals;


--
-- Table: projects
--
ALTER TABLE projects RENAME TO old_projects;

CREATE TABLE projects (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  url_name text NOT NULL,
  url_name_fc text NOT NULL,
  description text NOT NULL,
  is_public bool NOT NULL DEFAULT '1',
  owner int NOT NULL,
  FOREIGN KEY (owner) REFERENCES users(id)
);
--CREATE INDEX projects_idx_owner ON projects (owner);
--CREATE UNIQUE INDEX projects_name ON projects (name);
--CREATE UNIQUE INDEX projects_url_name ON projects (url_name);
--CREATE UNIQUE INDEX projects_url_name_fc ON projects (url_name_fc);

INSERT INTO projects SELECT * FROM old_projects;

DROP TABLE old_projects;


--
-- Table: purchase_lists
--
ALTER TABLE purchase_lists RENAME TO old_purchase_lists;

CREATE TABLE purchase_lists (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  name text NOT NULL,
  date date NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX purchase_lists_idx_project ON purchase_lists (project);
CREATE UNIQUE INDEX purchase_lists_project_name ON purchase_lists (project, name);

INSERT INTO purchase_lists SELECT * FROM old_purchase_lists;

DROP TABLE old_purchase_lists;


--
-- Table: quantities
--
ALTER TABLE quantities RENAME TO old_quantities;

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

INSERT INTO quantities SELECT * FROM old_quantities;

DROP TABLE old_quantities;


--
-- Table: recipe_ingredients
--
ALTER TABLE recipe_ingredients RENAME TO old_recipe_ingredients;

CREATE TABLE recipe_ingredients (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  recipe int NOT NULL,
  prepare bool NOT NULL,
  article int NOT NULL,
  unit int NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (article) REFERENCES articles(id),
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit),
  FOREIGN KEY (recipe) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id)
);
CREATE INDEX recipe_ingredients_idx_article ON recipe_ingredients (article);
CREATE INDEX recipe_ingredients_idx_article_unit ON recipe_ingredients (article, unit);
CREATE INDEX recipe_ingredients_idx_recipe ON recipe_ingredients (recipe);
CREATE INDEX recipe_ingredients_idx_unit ON recipe_ingredients (unit);

INSERT INTO recipe_ingredients SELECT * FROM old_recipe_ingredients;

DROP TABLE old_recipe_ingredients;


--
-- Table: recipes
--
ALTER TABLE recipes RENAME TO old_recipes;

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

INSERT INTO recipes SELECT * FROM old_recipes;

DROP TABLE old_recipes;


--
-- Table: recipes_tags
--
ALTER TABLE recipes_tags RENAME TO old_recipes_tags;

CREATE TABLE recipes_tags (
  recipe int NOT NULL,
  tag int NOT NULL,
  PRIMARY KEY (recipe, tag),
  FOREIGN KEY (recipe) REFERENCES recipes(id) ON DELETE CASCADE,
  FOREIGN KEY (tag) REFERENCES tags(id) ON DELETE CASCADE
);
CREATE INDEX recipes_tags_idx_recipe ON recipes_tags (recipe);
CREATE INDEX recipes_tags_idx_tag ON recipes_tags (tag);

INSERT INTO recipes_tags SELECT * FROM old_recipes_tags;

DROP TABLE old_recipes_tags;


--
-- Table: shop_sections
--
ALTER TABLE shop_sections RENAME TO old_shop_sections;

CREATE TABLE shop_sections (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  name text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX shop_sections_idx_project ON shop_sections (project);
CREATE UNIQUE INDEX shop_sections_project_name ON shop_sections (project, name);

INSERT INTO shop_sections SELECT * FROM old_shop_sections;

DROP TABLE old_shop_sections;


--
-- Table: tag_groups
--
ALTER TABLE tag_groups RENAME TO old_tag_groups;

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

INSERT INTO tag_groups SELECT * FROM old_tag_groups;

DROP TABLE old_tag_groups;


--
-- Table: tags
--
ALTER TABLE tags RENAME TO old_tags;

CREATE TABLE tags (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  tag_group int,
  name text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_group) REFERENCES tag_groups(id)
);
CREATE INDEX tags_idx_project ON tags (project);
CREATE INDEX tags_idx_tag_group ON tags (tag_group);
CREATE UNIQUE INDEX tags_project_name ON tags (project, name);

INSERT INTO tags SELECT * FROM old_tags;

DROP TABLE old_tags;


--
-- Table: terms_users
--
ALTER TABLE terms_users RENAME TO old_terms_users;

CREATE TABLE terms_users (
  terms int NOT NULL,
  user int NOT NULL,
  approved datetime NOT NULL,
  PRIMARY KEY (terms, user),
  FOREIGN KEY (terms) REFERENCES terms(id),
  FOREIGN KEY (user) REFERENCES users(id) ON DELETE CASCADE
);
--CREATE INDEX terms_users_idx_terms ON terms_users (terms);
--CREATE INDEX terms_users_idx_user ON terms_users (user);

INSERT INTO terms_users SELECT * FROM old_terms_users;

DROP TABLE old_terms_users;


--
-- Table: units
--
ALTER TABLE units RENAME TO old_units;

CREATE TABLE units (
  id INTEGER PRIMARY KEY NOT NULL,
  project int NOT NULL,
  quantity int NOT NULL,
  to_quantity_default real,
  space bool NOT NULL,
  short_name text NOT NULL,
  long_name text NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (quantity) REFERENCES quantities(id)
);
CREATE INDEX units_idx_project ON units (project);
CREATE INDEX units_idx_quantity ON units (quantity);
CREATE UNIQUE INDEX units_project_long_name ON units (project, long_name);

INSERT INTO units SELECT * FROM old_units;

DROP TABLE old_units;

COMMIT;
