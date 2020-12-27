-- Convert schema 'share/ddl/_source/deploy/21/001-auto.yml' to 'share/ddl/_source/deploy/22/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE articles_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  shop_section_id integer,
  shelf_life_days integer,
  preorder_servings integer,
  preorder_workdays integer,
  name text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (shop_section_id) REFERENCES shop_sections(id)
);

;
INSERT INTO articles_temp_alter( id, project_id, shop_section_id, shelf_life_days, preorder_servings, preorder_workdays, name, comment) SELECT id, project_id, shop_section_id, shelf_life_days, preorder_servings, preorder_workdays, name, comment FROM articles;

;
DROP TABLE articles;

;
CREATE TABLE articles (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  shop_section_id integer,
  shelf_life_days integer,
  preorder_servings integer,
  preorder_workdays integer,
  name text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (shop_section_id) REFERENCES shop_sections(id)
);

;
CREATE INDEX articles_idx_project_id ON articles (project_id);

;
CREATE INDEX articles_idx_shop_section_id ON articles (shop_section_id);

;
CREATE UNIQUE INDEX articles_project_id_name ON articles (project_id, name);

;
INSERT INTO articles SELECT id, project_id, shop_section_id, shelf_life_days, preorder_servings, preorder_workdays, name, comment FROM articles_temp_alter;

;
DROP TABLE articles_temp_alter;

;
CREATE TEMPORARY TABLE articles_tags_temp_alter (
  article_id integer NOT NULL,
  tag_id integer NOT NULL,
  PRIMARY KEY (article_id, tag_id),
  FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

;
INSERT INTO articles_tags_temp_alter( article_id, tag_id) SELECT article_id, tag_id FROM articles_tags;

;
DROP TABLE articles_tags;

;
CREATE TABLE articles_tags (
  article_id integer NOT NULL,
  tag_id integer NOT NULL,
  PRIMARY KEY (article_id, tag_id),
  FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

;
CREATE INDEX articles_tags_idx_article_id ON articles_tags (article_id);

;
CREATE INDEX articles_tags_idx_tag_id ON articles_tags (tag_id);

;
INSERT INTO articles_tags SELECT article_id, tag_id FROM articles_tags_temp_alter;

;
DROP TABLE articles_tags_temp_alter;

;
CREATE TEMPORARY TABLE articles_units_temp_alter (
  article_id integer NOT NULL,
  unit_id integer NOT NULL,
  PRIMARY KEY (article_id, unit_id),
  FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
  FOREIGN KEY (unit_id) REFERENCES units(id)
);

;
INSERT INTO articles_units_temp_alter( article_id, unit_id) SELECT article_id, unit_id FROM articles_units;

;
DROP TABLE articles_units;

;
CREATE TABLE articles_units (
  article_id integer NOT NULL,
  unit_id integer NOT NULL,
  PRIMARY KEY (article_id, unit_id),
  FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
  FOREIGN KEY (unit_id) REFERENCES units(id)
);

;
CREATE INDEX articles_units_idx_article_id ON articles_units (article_id);

;
CREATE INDEX articles_units_idx_unit_id ON articles_units (unit_id);

;
INSERT INTO articles_units SELECT article_id, unit_id FROM articles_units_temp_alter;

;
DROP TABLE articles_units_temp_alter;

;
CREATE TEMPORARY TABLE blacklist_emails_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  email_fc text NOT NULL,
  email_type text NOT NULL DEFAULT 'cleartext',
  comment text NOT NULL,
  created timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

;
INSERT INTO blacklist_emails_temp_alter( id, email_fc, email_type, comment, created) SELECT id, email_fc, email_type, comment, created FROM blacklist_emails;

;
DROP TABLE blacklist_emails;

;
CREATE TABLE blacklist_emails (
  id INTEGER PRIMARY KEY NOT NULL,
  email_fc text NOT NULL,
  email_type text NOT NULL DEFAULT 'cleartext',
  comment text NOT NULL,
  created timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

;
CREATE UNIQUE INDEX blacklist_emails_email_fc ON blacklist_emails (email_fc);

;
INSERT INTO blacklist_emails SELECT id, email_fc, email_type, comment, created FROM blacklist_emails_temp_alter;

;
DROP TABLE blacklist_emails_temp_alter;

;
CREATE TEMPORARY TABLE blacklist_usernames_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  username_fc text NOT NULL,
  username_type text NOT NULL DEFAULT 'cleartext',
  comment text NOT NULL,
  created timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

;
INSERT INTO blacklist_usernames_temp_alter( id, username_fc, username_type, comment, created) SELECT id, username_fc, username_type, comment, created FROM blacklist_usernames;

;
DROP TABLE blacklist_usernames;

;
CREATE TABLE blacklist_usernames (
  id INTEGER PRIMARY KEY NOT NULL,
  username_fc text NOT NULL,
  username_type text NOT NULL DEFAULT 'cleartext',
  comment text NOT NULL,
  created timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

;
CREATE UNIQUE INDEX blacklist_usernames_username_fc ON blacklist_usernames (username_fc);

;
INSERT INTO blacklist_usernames SELECT id, username_fc, username_type, comment, created FROM blacklist_usernames_temp_alter;

;
DROP TABLE blacklist_usernames_temp_alter;

;
CREATE TEMPORARY TABLE dish_ingredients_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  position integer NOT NULL DEFAULT 1,
  dish_id integer NOT NULL,
  prepare boolean NOT NULL,
  article_id integer NOT NULL,
  unit_id integer NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  item_id integer,
  FOREIGN KEY (article_id) REFERENCES articles(id),
  FOREIGN KEY (article_id, unit_id) REFERENCES articles_units(article_id, unit_id),
  FOREIGN KEY (dish_id) REFERENCES dishes(id) ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE SET NULL,
  FOREIGN KEY (unit_id) REFERENCES units(id)
);

;
INSERT INTO dish_ingredients_temp_alter( id, position, dish_id, prepare, article_id, unit_id, value, comment, item_id) SELECT id, position, dish_id, prepare, article_id, unit_id, value, comment, item_id FROM dish_ingredients;

;
DROP TABLE dish_ingredients;

;
CREATE TABLE dish_ingredients (
  id INTEGER PRIMARY KEY NOT NULL,
  position integer NOT NULL DEFAULT 1,
  dish_id integer NOT NULL,
  prepare boolean NOT NULL,
  article_id integer NOT NULL,
  unit_id integer NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  item_id integer,
  FOREIGN KEY (article_id) REFERENCES articles(id),
  FOREIGN KEY (article_id, unit_id) REFERENCES articles_units(article_id, unit_id),
  FOREIGN KEY (dish_id) REFERENCES dishes(id) ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE SET NULL,
  FOREIGN KEY (unit_id) REFERENCES units(id)
);

;
CREATE INDEX dish_ingredients_idx_article_id ON dish_ingredients (article_id);

;
CREATE INDEX dish_ingredients_idx_article_id_unit_id ON dish_ingredients (article_id, unit_id);

;
CREATE INDEX dish_ingredients_idx_dish_id ON dish_ingredients (dish_id);

;
CREATE INDEX dish_ingredients_idx_item_id ON dish_ingredients (item_id);

;
CREATE INDEX dish_ingredients_idx_unit_id ON dish_ingredients (unit_id);

;
INSERT INTO dish_ingredients SELECT id, position, dish_id, prepare, article_id, unit_id, value, comment, item_id FROM dish_ingredients_temp_alter;

;
DROP TABLE dish_ingredients_temp_alter;

;
CREATE TEMPORARY TABLE dishes_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  meal_id integer NOT NULL,
  from_recipe_id integer,
  name text NOT NULL,
  servings integer NOT NULL,
  prepare_at_meal_id integer,
  preparation text NOT NULL,
  description text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
  FOREIGN KEY (prepare_at_meal_id) REFERENCES meals(id),
  FOREIGN KEY (from_recipe_id) REFERENCES recipes(id)
);

;
INSERT INTO dishes_temp_alter( id, meal_id, from_recipe_id, name, servings, prepare_at_meal_id, preparation, description, comment) SELECT id, meal_id, from_recipe_id, name, servings, prepare_at_meal_id, preparation, description, comment FROM dishes;

;
DROP TABLE dishes;

;
CREATE TABLE dishes (
  id INTEGER PRIMARY KEY NOT NULL,
  meal_id integer NOT NULL,
  from_recipe_id integer,
  name text NOT NULL,
  servings integer NOT NULL,
  prepare_at_meal_id integer,
  preparation text NOT NULL,
  description text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
  FOREIGN KEY (prepare_at_meal_id) REFERENCES meals(id),
  FOREIGN KEY (from_recipe_id) REFERENCES recipes(id)
);

;
CREATE INDEX dishes_idx_meal_id ON dishes (meal_id);

;
CREATE INDEX dishes_idx_prepare_at_meal_id ON dishes (prepare_at_meal_id);

;
CREATE INDEX dishes_idx_from_recipe_id ON dishes (from_recipe_id);

;
INSERT INTO dishes SELECT id, meal_id, from_recipe_id, name, servings, prepare_at_meal_id, preparation, description, comment FROM dishes_temp_alter;

;
DROP TABLE dishes_temp_alter;

;
CREATE TEMPORARY TABLE dishes_tags_temp_alter (
  dish_id integer NOT NULL,
  tag_id integer NOT NULL,
  PRIMARY KEY (dish_id, tag_id),
  FOREIGN KEY (dish_id) REFERENCES dishes(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

;
INSERT INTO dishes_tags_temp_alter( dish_id, tag_id) SELECT dish_id, tag_id FROM dishes_tags;

;
DROP TABLE dishes_tags;

;
CREATE TABLE dishes_tags (
  dish_id integer NOT NULL,
  tag_id integer NOT NULL,
  PRIMARY KEY (dish_id, tag_id),
  FOREIGN KEY (dish_id) REFERENCES dishes(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

;
CREATE INDEX dishes_tags_idx_dish_id ON dishes_tags (dish_id);

;
CREATE INDEX dishes_tags_idx_tag_id ON dishes_tags (tag_id);

;
INSERT INTO dishes_tags SELECT dish_id, tag_id FROM dishes_tags_temp_alter;

;
DROP TABLE dishes_tags_temp_alter;

;
CREATE TEMPORARY TABLE faqs_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  position integer NOT NULL DEFAULT 1,
  anchor text NOT NULL,
  question_md text NOT NULL,
  answer_md text NOT NULL
);

;
INSERT INTO faqs_temp_alter( id, position, anchor, question_md, answer_md) SELECT id, position, anchor, question_md, answer_md FROM faqs;

;
DROP TABLE faqs;

;
CREATE TABLE faqs (
  id INTEGER PRIMARY KEY NOT NULL,
  position integer NOT NULL DEFAULT 1,
  anchor text NOT NULL,
  question_md text NOT NULL,
  answer_md text NOT NULL
);

;
CREATE UNIQUE INDEX faqs_anchor ON faqs (anchor);

;
INSERT INTO faqs SELECT id, position, anchor, question_md, answer_md FROM faqs_temp_alter;

;
DROP TABLE faqs_temp_alter;

;
CREATE TEMPORARY TABLE items_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  purchase_list_id integer NOT NULL,
  value real NOT NULL,
  offset real NOT NULL DEFAULT 0,
  unit_id integer NOT NULL,
  article_id integer NOT NULL,
  purchased boolean NOT NULL DEFAULT 0,
  comment text NOT NULL,
  FOREIGN KEY (article_id) REFERENCES articles(id),
  FOREIGN KEY (article_id, unit_id) REFERENCES articles_units(article_id, unit_id),
  FOREIGN KEY (purchase_list_id) REFERENCES purchase_lists(id) ON DELETE CASCADE,
  FOREIGN KEY (unit_id) REFERENCES units(id)
);

;
INSERT INTO items_temp_alter( id, purchase_list_id, value, offset, unit_id, article_id, purchased, comment) SELECT id, purchase_list_id, value, offset, unit_id, article_id, purchased, comment FROM items;

;
DROP TABLE items;

;
CREATE TABLE items (
  id INTEGER PRIMARY KEY NOT NULL,
  purchase_list_id integer NOT NULL,
  value real NOT NULL,
  offset real NOT NULL DEFAULT 0,
  unit_id integer NOT NULL,
  article_id integer NOT NULL,
  purchased boolean NOT NULL DEFAULT 0,
  comment text NOT NULL,
  FOREIGN KEY (article_id) REFERENCES articles(id),
  FOREIGN KEY (article_id, unit_id) REFERENCES articles_units(article_id, unit_id),
  FOREIGN KEY (purchase_list_id) REFERENCES purchase_lists(id) ON DELETE CASCADE,
  FOREIGN KEY (unit_id) REFERENCES units(id)
);

;
CREATE INDEX items_idx_article_id ON items (article_id);

;
CREATE INDEX items_idx_article_id_unit_id ON items (article_id, unit_id);

;
CREATE INDEX items_idx_purchase_list_id ON items (purchase_list_id);

;
CREATE INDEX items_idx_unit_id ON items (unit_id);

;
CREATE UNIQUE INDEX items_purchase_list_id_article_id_unit_id ON items (purchase_list_id, article_id, unit_id);

;
INSERT INTO items SELECT id, purchase_list_id, value, offset, unit_id, article_id, purchased, comment FROM items_temp_alter;

;
DROP TABLE items_temp_alter;

;
CREATE TEMPORARY TABLE meals_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  date date NOT NULL,
  name text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

;
INSERT INTO meals_temp_alter( id, project_id, date, name, comment) SELECT id, project_id, date, name, comment FROM meals;

;
DROP TABLE meals;

;
CREATE TABLE meals (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  date date NOT NULL,
  name text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

;
CREATE INDEX meals_idx_project_id ON meals (project_id);

;
CREATE UNIQUE INDEX meals_project_id_date_name ON meals (project_id, date, name);

;
INSERT INTO meals SELECT id, project_id, date, name, comment FROM meals_temp_alter;

;
DROP TABLE meals_temp_alter;

;
CREATE TEMPORARY TABLE organizations_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  name_fc text NOT NULL,
  owner_id integer NOT NULL,
  description_md text NOT NULL,
  display_name text NOT NULL,
  admin_comment text NOT NULL DEFAULT '',
  created timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES users(id)
);

;
INSERT INTO organizations_temp_alter( id, name, name_fc, owner_id, description_md, display_name, admin_comment, created) SELECT id, name, name_fc, owner_id, description_md, display_name, admin_comment, created FROM organizations;

;
DROP TABLE organizations;

;
CREATE TABLE organizations (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  name_fc text NOT NULL,
  owner_id integer NOT NULL,
  description_md text NOT NULL,
  display_name text NOT NULL,
  admin_comment text NOT NULL DEFAULT '',
  created timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES users(id)
);

;
CREATE INDEX organizations_idx_owner_id ON organizations (owner_id);

;
CREATE UNIQUE INDEX organizations_name ON organizations (name);

;
CREATE UNIQUE INDEX organizations_name_fc ON organizations (name_fc);

;
INSERT INTO organizations SELECT id, name, name_fc, owner_id, description_md, display_name, admin_comment, created FROM organizations_temp_alter;

;
DROP TABLE organizations_temp_alter;

;
CREATE TEMPORARY TABLE organizations_projects_temp_alter (
  organization_id integer NOT NULL,
  project_id integer NOT NULL,
  role text NOT NULL,
  PRIMARY KEY (organization_id, project_id),
  FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

;
INSERT INTO organizations_projects_temp_alter( organization_id, project_id, role) SELECT organization_id, project_id, role FROM organizations_projects;

;
DROP TABLE organizations_projects;

;
CREATE TABLE organizations_projects (
  organization_id integer NOT NULL,
  project_id integer NOT NULL,
  role text NOT NULL,
  PRIMARY KEY (organization_id, project_id),
  FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

;
CREATE INDEX organizations_projects_idx_organization_id ON organizations_projects (organization_id);

;
CREATE INDEX organizations_projects_idx_project_id ON organizations_projects (project_id);

;
INSERT INTO organizations_projects SELECT organization_id, project_id, role FROM organizations_projects_temp_alter;

;
DROP TABLE organizations_projects_temp_alter;

;
CREATE TEMPORARY TABLE organizations_users_temp_alter (
  organization_id integer NOT NULL,
  user_id integer NOT NULL,
  role text NOT NULL,
  PRIMARY KEY (organization_id, user_id),
  FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
INSERT INTO organizations_users_temp_alter( organization_id, user_id, role) SELECT organization_id, user_id, role FROM organizations_users;

;
DROP TABLE organizations_users;

;
CREATE TABLE organizations_users (
  organization_id integer NOT NULL,
  user_id integer NOT NULL,
  role text NOT NULL,
  PRIMARY KEY (organization_id, user_id),
  FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
CREATE INDEX organizations_users_idx_organization_id ON organizations_users (organization_id);

;
CREATE INDEX organizations_users_idx_user_id ON organizations_users (user_id);

;
INSERT INTO organizations_users SELECT organization_id, user_id, role FROM organizations_users_temp_alter;

;
DROP TABLE organizations_users_temp_alter;

;
CREATE TEMPORARY TABLE projects_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  url_name text NOT NULL,
  url_name_fc text NOT NULL,
  description text NOT NULL,
  is_public boolean NOT NULL DEFAULT 1,
  owner_id integer NOT NULL,
  created timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  archived timestamp without time zone,
  FOREIGN KEY (owner_id) REFERENCES users(id)
);

;
INSERT INTO projects_temp_alter( id, name, url_name, url_name_fc, description, is_public, owner_id, created, archived) SELECT id, name, url_name, url_name_fc, description, is_public, owner_id, created, archived FROM projects;

;
DROP TABLE projects;

;
CREATE TABLE projects (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  url_name text NOT NULL,
  url_name_fc text NOT NULL,
  description text NOT NULL,
  is_public boolean NOT NULL DEFAULT 1,
  owner_id integer NOT NULL,
  created timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  archived timestamp without time zone,
  FOREIGN KEY (owner_id) REFERENCES users(id)
);

;
CREATE INDEX projects_idx_owner_id ON projects (owner_id);

;
CREATE UNIQUE INDEX projects_name ON projects (name);

;
CREATE UNIQUE INDEX projects_url_name ON projects (url_name);

;
CREATE UNIQUE INDEX projects_url_name_fc ON projects (url_name_fc);

;
INSERT INTO projects SELECT id, name, url_name, url_name_fc, description, is_public, owner_id, created, archived FROM projects_temp_alter;

;
DROP TABLE projects_temp_alter;

;
CREATE TEMPORARY TABLE projects_users_temp_alter (
  project_id integer NOT NULL,
  user_id integer NOT NULL,
  role text NOT NULL,
  PRIMARY KEY (project_id, user_id),
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
INSERT INTO projects_users_temp_alter( project_id, user_id, role) SELECT project_id, user_id, role FROM projects_users;

;
DROP TABLE projects_users;

;
CREATE TABLE projects_users (
  project_id integer NOT NULL,
  user_id integer NOT NULL,
  role text NOT NULL,
  PRIMARY KEY (project_id, user_id),
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
CREATE INDEX projects_users_idx_project_id ON projects_users (project_id);

;
CREATE INDEX projects_users_idx_user_id ON projects_users (user_id);

;
INSERT INTO projects_users SELECT project_id, user_id, role FROM projects_users_temp_alter;

;
DROP TABLE projects_users_temp_alter;

;
CREATE TEMPORARY TABLE purchase_lists_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  name text NOT NULL,
  date date NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

;
INSERT INTO purchase_lists_temp_alter( id, project_id, name, date) SELECT id, project_id, name, date FROM purchase_lists;

;
DROP TABLE purchase_lists;

;
CREATE TABLE purchase_lists (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  name text NOT NULL,
  date date NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

;
CREATE INDEX purchase_lists_idx_project_id ON purchase_lists (project_id);

;
CREATE UNIQUE INDEX purchase_lists_project_id_name ON purchase_lists (project_id, name);

;
INSERT INTO purchase_lists SELECT id, project_id, name, date FROM purchase_lists_temp_alter;

;
DROP TABLE purchase_lists_temp_alter;

;
CREATE TEMPORARY TABLE quantities_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  name text NOT NULL,
  default_unit_id integer,
  FOREIGN KEY (default_unit_id) REFERENCES units(id),
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

;
INSERT INTO quantities_temp_alter( id, project_id, name, default_unit_id) SELECT id, project_id, name, default_unit_id FROM quantities;

;
DROP TABLE quantities;

;
CREATE TABLE quantities (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  name text NOT NULL,
  default_unit_id integer,
  FOREIGN KEY (default_unit_id) REFERENCES units(id),
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

;
CREATE INDEX quantities_idx_default_unit_id ON quantities (default_unit_id);

;
CREATE INDEX quantities_idx_project_id ON quantities (project_id);

;
CREATE UNIQUE INDEX quantities_project_id_name ON quantities (project_id, name);

;
INSERT INTO quantities SELECT id, project_id, name, default_unit_id FROM quantities_temp_alter;

;
DROP TABLE quantities_temp_alter;

;
CREATE TEMPORARY TABLE recipe_ingredients_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  position integer NOT NULL DEFAULT 1,
  recipe_id integer NOT NULL,
  prepare boolean NOT NULL,
  article_id integer NOT NULL,
  unit_id integer NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (article_id) REFERENCES articles(id),
  FOREIGN KEY (article_id, unit_id) REFERENCES articles_units(article_id, unit_id),
  FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit_id) REFERENCES units(id)
);

;
INSERT INTO recipe_ingredients_temp_alter( id, position, recipe_id, prepare, article_id, unit_id, value, comment) SELECT id, position, recipe_id, prepare, article_id, unit_id, value, comment FROM recipe_ingredients;

;
DROP TABLE recipe_ingredients;

;
CREATE TABLE recipe_ingredients (
  id INTEGER PRIMARY KEY NOT NULL,
  position integer NOT NULL DEFAULT 1,
  recipe_id integer NOT NULL,
  prepare boolean NOT NULL,
  article_id integer NOT NULL,
  unit_id integer NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (article_id) REFERENCES articles(id),
  FOREIGN KEY (article_id, unit_id) REFERENCES articles_units(article_id, unit_id),
  FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit_id) REFERENCES units(id)
);

;
CREATE INDEX recipe_ingredients_idx_article_id ON recipe_ingredients (article_id);

;
CREATE INDEX recipe_ingredients_idx_article_id_unit_id ON recipe_ingredients (article_id, unit_id);

;
CREATE INDEX recipe_ingredients_idx_recipe_id ON recipe_ingredients (recipe_id);

;
CREATE INDEX recipe_ingredients_idx_unit_id ON recipe_ingredients (unit_id);

;
INSERT INTO recipe_ingredients SELECT id, position, recipe_id, prepare, article_id, unit_id, value, comment FROM recipe_ingredients_temp_alter;

;
DROP TABLE recipe_ingredients_temp_alter;

;
CREATE TEMPORARY TABLE recipes_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  name text NOT NULL,
  preparation text NOT NULL,
  description text NOT NULL,
  servings integer NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

;
INSERT INTO recipes_temp_alter( id, project_id, name, preparation, description, servings) SELECT id, project_id, name, preparation, description, servings FROM recipes;

;
DROP TABLE recipes;

;
CREATE TABLE recipes (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  name text NOT NULL,
  preparation text NOT NULL,
  description text NOT NULL,
  servings integer NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

;
CREATE INDEX recipes_idx_project_id ON recipes (project_id);

;
CREATE UNIQUE INDEX recipes_project_id_name ON recipes (project_id, name);

;
INSERT INTO recipes SELECT id, project_id, name, preparation, description, servings FROM recipes_temp_alter;

;
DROP TABLE recipes_temp_alter;

;
CREATE TEMPORARY TABLE recipes_tags_temp_alter (
  recipe_id integer NOT NULL,
  tag_id integer NOT NULL,
  PRIMARY KEY (recipe_id, tag_id),
  FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

;
INSERT INTO recipes_tags_temp_alter( recipe_id, tag_id) SELECT recipe_id, tag_id FROM recipes_tags;

;
DROP TABLE recipes_tags;

;
CREATE TABLE recipes_tags (
  recipe_id integer NOT NULL,
  tag_id integer NOT NULL,
  PRIMARY KEY (recipe_id, tag_id),
  FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

;
CREATE INDEX recipes_tags_idx_recipe_id ON recipes_tags (recipe_id);

;
CREATE INDEX recipes_tags_idx_tag_id ON recipes_tags (tag_id);

;
INSERT INTO recipes_tags SELECT recipe_id, tag_id FROM recipes_tags_temp_alter;

;
DROP TABLE recipes_tags_temp_alter;

;
CREATE TEMPORARY TABLE roles_users_temp_alter (
  role text NOT NULL,
  user_id integer NOT NULL,
  PRIMARY KEY (role, user_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
INSERT INTO roles_users_temp_alter( role, user_id) SELECT role, user_id FROM roles_users;

;
DROP TABLE roles_users;

;
CREATE TABLE roles_users (
  role text NOT NULL,
  user_id integer NOT NULL,
  PRIMARY KEY (role, user_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
CREATE INDEX roles_users_idx_user_id ON roles_users (user_id);

;
INSERT INTO roles_users SELECT role, user_id FROM roles_users_temp_alter;

;
DROP TABLE roles_users_temp_alter;

;
CREATE TEMPORARY TABLE sessions_temp_alter (
  id text NOT NULL,
  expires integer,
  session_data text,
  PRIMARY KEY (id)
);

;
INSERT INTO sessions_temp_alter( id, expires, session_data) SELECT id, expires, session_data FROM sessions;

;
DROP TABLE sessions;

;
CREATE TABLE sessions (
  id text NOT NULL,
  expires integer,
  session_data text,
  PRIMARY KEY (id)
);

;
INSERT INTO sessions SELECT id, expires, session_data FROM sessions_temp_alter;

;
DROP TABLE sessions_temp_alter;

;
CREATE TEMPORARY TABLE shop_sections_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  name text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

;
INSERT INTO shop_sections_temp_alter( id, project_id, name) SELECT id, project_id, name FROM shop_sections;

;
DROP TABLE shop_sections;

;
CREATE TABLE shop_sections (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  name text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

;
CREATE INDEX shop_sections_idx_project_id ON shop_sections (project_id);

;
CREATE UNIQUE INDEX shop_sections_project_id_name ON shop_sections (project_id, name);

;
INSERT INTO shop_sections SELECT id, project_id, name FROM shop_sections_temp_alter;

;
DROP TABLE shop_sections_temp_alter;

;
CREATE TEMPORARY TABLE tag_groups_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  color integer,
  name text NOT NULL,
  comment text NOT NULL DEFAULT '',
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

;
INSERT INTO tag_groups_temp_alter( id, project_id, color, name, comment) SELECT id, project_id, color, name, comment FROM tag_groups;

;
DROP TABLE tag_groups;

;
CREATE TABLE tag_groups (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  color integer,
  name text NOT NULL,
  comment text NOT NULL DEFAULT '',
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

;
CREATE INDEX tag_groups_idx_project_id ON tag_groups (project_id);

;
CREATE UNIQUE INDEX tag_groups_project_id_name ON tag_groups (project_id, name);

;
INSERT INTO tag_groups SELECT id, project_id, color, name, comment FROM tag_groups_temp_alter;

;
DROP TABLE tag_groups_temp_alter;

;
CREATE TEMPORARY TABLE tags_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  tag_group_id integer,
  name text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_group_id) REFERENCES tag_groups(id)
);

;
INSERT INTO tags_temp_alter( id, project_id, tag_group_id, name) SELECT id, project_id, tag_group_id, name FROM tags;

;
DROP TABLE tags;

;
CREATE TABLE tags (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  tag_group_id integer,
  name text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_group_id) REFERENCES tag_groups(id)
);

;
CREATE INDEX tags_idx_project_id ON tags (project_id);

;
CREATE INDEX tags_idx_tag_group_id ON tags (tag_group_id);

;
CREATE UNIQUE INDEX tags_project_id_name ON tags (project_id, name);

;
INSERT INTO tags SELECT id, project_id, tag_group_id, name FROM tags_temp_alter;

;
DROP TABLE tags_temp_alter;

;
CREATE TEMPORARY TABLE terms_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  valid_from date NOT NULL,
  content_md text NOT NULL
);

;
INSERT INTO terms_temp_alter( id, valid_from, content_md) SELECT id, valid_from, content_md FROM terms;

;
DROP TABLE terms;

;
CREATE TABLE terms (
  id INTEGER PRIMARY KEY NOT NULL,
  valid_from date NOT NULL,
  content_md text NOT NULL
);

;
CREATE UNIQUE INDEX terms_valid_from ON terms (valid_from);

;
INSERT INTO terms SELECT id, valid_from, content_md FROM terms_temp_alter;

;
DROP TABLE terms_temp_alter;

;
CREATE TEMPORARY TABLE terms_users_temp_alter (
  terms_id integer NOT NULL,
  user_id integer NOT NULL,
  approved timestamp without time zone NOT NULL,
  PRIMARY KEY (terms_id, user_id),
  FOREIGN KEY (terms_id) REFERENCES terms(id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
INSERT INTO terms_users_temp_alter( terms_id, user_id, approved) SELECT terms_id, user_id, approved FROM terms_users;

;
DROP TABLE terms_users;

;
CREATE TABLE terms_users (
  terms_id integer NOT NULL,
  user_id integer NOT NULL,
  approved timestamp without time zone NOT NULL,
  PRIMARY KEY (terms_id, user_id),
  FOREIGN KEY (terms_id) REFERENCES terms(id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
CREATE INDEX terms_users_idx_terms_id ON terms_users (terms_id);

;
CREATE INDEX terms_users_idx_user_id ON terms_users (user_id);

;
INSERT INTO terms_users SELECT terms_id, user_id, approved FROM terms_users_temp_alter;

;
DROP TABLE terms_users_temp_alter;

;
CREATE TEMPORARY TABLE units_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  quantity_id integer NOT NULL,
  to_quantity_default real,
  space boolean NOT NULL,
  short_name text NOT NULL,
  long_name text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (quantity_id) REFERENCES quantities(id)
);

;
INSERT INTO units_temp_alter( id, project_id, quantity_id, to_quantity_default, space, short_name, long_name) SELECT id, project_id, quantity_id, to_quantity_default, space, short_name, long_name FROM units;

;
DROP TABLE units;

;
CREATE TABLE units (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id integer NOT NULL,
  quantity_id integer NOT NULL,
  to_quantity_default real,
  space boolean NOT NULL,
  short_name text NOT NULL,
  long_name text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (quantity_id) REFERENCES quantities(id)
);

;
CREATE INDEX units_idx_project_id ON units (project_id);

;
CREATE INDEX units_idx_quantity_id ON units (quantity_id);

;
CREATE UNIQUE INDEX units_project_id_long_name ON units (project_id, long_name);

;
INSERT INTO units SELECT id, project_id, quantity_id, to_quantity_default, space, short_name, long_name FROM units_temp_alter;

;
DROP TABLE units_temp_alter;

;
CREATE TEMPORARY TABLE users_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  name_fc text NOT NULL,
  password_hash text NOT NULL,
  display_name text NOT NULL,
  admin_comment text NOT NULL DEFAULT '',
  email_fc text NOT NULL,
  email_verified timestamp without time zone,
  token_hash text,
  token_expires timestamp without time zone,
  created timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

;
INSERT INTO users_temp_alter( id, name, name_fc, password_hash, display_name, admin_comment, email_fc, email_verified, token_hash, token_expires, created) SELECT id, name, name_fc, password_hash, display_name, admin_comment, email_fc, email_verified, token_hash, token_expires, created FROM users;

;
DROP TABLE users;

;
CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  name_fc text NOT NULL,
  password_hash text NOT NULL,
  display_name text NOT NULL,
  admin_comment text NOT NULL DEFAULT '',
  email_fc text NOT NULL,
  email_verified timestamp without time zone,
  token_hash text,
  token_expires timestamp without time zone,
  created timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

;
CREATE UNIQUE INDEX users_email_fc ON users (email_fc);

;
CREATE UNIQUE INDEX users_name ON users (name);

;
CREATE UNIQUE INDEX users_name_fc ON users (name_fc);

;
CREATE UNIQUE INDEX users_password_hash ON users (password_hash);

;
CREATE UNIQUE INDEX users_token_hash ON users (token_hash);

;
INSERT INTO users SELECT id, name, name_fc, password_hash, display_name, admin_comment, email_fc, email_verified, token_hash, token_expires, created FROM users_temp_alter;

;
DROP TABLE users_temp_alter;

;

COMMIT;

