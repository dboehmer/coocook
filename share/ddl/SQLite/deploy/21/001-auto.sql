-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Sun Mar 29 13:21:59 2020
-- 

;
BEGIN TRANSACTION;
--
-- Table: blacklist_emails
--
CREATE TABLE blacklist_emails (
  id INTEGER PRIMARY KEY NOT NULL,
  email_fc text NOT NULL,
  email_type text NOT NULL DEFAULT 'cleartext',
  comment text NOT NULL,
  created datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX blacklist_emails_email_fc ON blacklist_emails (email_fc);
--
-- Table: blacklist_usernames
--
CREATE TABLE blacklist_usernames (
  id INTEGER PRIMARY KEY NOT NULL,
  username_fc text NOT NULL,
  username_type text NOT NULL DEFAULT 'cleartext',
  comment text NOT NULL,
  created datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX blacklist_usernames_username_fc ON blacklist_usernames (username_fc);
--
-- Table: faqs
--
CREATE TABLE faqs (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  anchor text NOT NULL,
  question_md text NOT NULL,
  answer_md text NOT NULL
);
CREATE UNIQUE INDEX faqs_anchor ON faqs (anchor);
--
-- Table: sessions
--
CREATE TABLE sessions (
  id text NOT NULL,
  expires int,
  session_data text,
  PRIMARY KEY (id)
);
--
-- Table: terms
--
CREATE TABLE terms (
  id INTEGER PRIMARY KEY NOT NULL,
  valid_from date NOT NULL,
  content_md text NOT NULL
);
CREATE UNIQUE INDEX terms_valid_from ON terms (valid_from);
--
-- Table: users
--
CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  name_fc text NOT NULL,
  password_hash text NOT NULL,
  display_name text NOT NULL,
  admin_comment text NOT NULL DEFAULT '',
  email_fc text NOT NULL,
  email_verified datetime,
  token_hash text,
  token_expires datetime,
  created datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX users_email_fc ON users (email_fc);
CREATE UNIQUE INDEX users_name ON users (name);
CREATE UNIQUE INDEX users_name_fc ON users (name_fc);
CREATE UNIQUE INDEX users_password_hash ON users (password_hash);
CREATE UNIQUE INDEX users_token_hash ON users (token_hash);
--
-- Table: organizations
--
CREATE TABLE organizations (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  name_fc text NOT NULL,
  owner_id int NOT NULL,
  description_md text NOT NULL,
  display_name text NOT NULL,
  admin_comment text NOT NULL DEFAULT '',
  created datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES users(id)
);
CREATE INDEX organizations_idx_owner_id ON organizations (owner_id);
CREATE UNIQUE INDEX organizations_name ON organizations (name);
CREATE UNIQUE INDEX organizations_name_fc ON organizations (name_fc);
--
-- Table: projects
--
CREATE TABLE projects (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  url_name text NOT NULL,
  url_name_fc text NOT NULL,
  description text NOT NULL,
  is_public bool NOT NULL DEFAULT '1',
  owner_id int NOT NULL,
  created datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  archived datetime,
  FOREIGN KEY (owner_id) REFERENCES users(id)
);
CREATE INDEX projects_idx_owner_id ON projects (owner_id);
CREATE UNIQUE INDEX projects_name ON projects (name);
CREATE UNIQUE INDEX projects_url_name ON projects (url_name);
CREATE UNIQUE INDEX projects_url_name_fc ON projects (url_name_fc);
--
-- Table: roles_users
--
CREATE TABLE roles_users (
  role text NOT NULL,
  user_id int NOT NULL,
  PRIMARY KEY (role, user_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX roles_users_idx_user_id ON roles_users (user_id);
--
-- Table: meals
--
CREATE TABLE meals (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id int NOT NULL,
  date date NOT NULL,
  name text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX meals_idx_project_id ON meals (project_id);
CREATE UNIQUE INDEX meals_project_id_date_name ON meals (project_id, date, name);
--
-- Table: organizations_users
--
CREATE TABLE organizations_users (
  organization_id int NOT NULL,
  user_id int NOT NULL,
  role text NOT NULL,
  PRIMARY KEY (organization_id, user_id),
  FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX organizations_users_idx_organization_id ON organizations_users (organization_id);
CREATE INDEX organizations_users_idx_user_id ON organizations_users (user_id);
--
-- Table: projects_users
--
CREATE TABLE projects_users (
  project_id int NOT NULL,
  user_id int NOT NULL,
  role text NOT NULL,
  PRIMARY KEY (project_id, user_id),
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX projects_users_idx_project_id ON projects_users (project_id);
CREATE INDEX projects_users_idx_user_id ON projects_users (user_id);
--
-- Table: purchase_lists
--
CREATE TABLE purchase_lists (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id int NOT NULL,
  name text NOT NULL,
  date date NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX purchase_lists_idx_project_id ON purchase_lists (project_id);
CREATE UNIQUE INDEX purchase_lists_project_id_name ON purchase_lists (project_id, name);
--
-- Table: recipes
--
CREATE TABLE recipes (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id int NOT NULL,
  name text NOT NULL,
  preparation text NOT NULL,
  description text NOT NULL,
  servings int NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX recipes_idx_project_id ON recipes (project_id);
CREATE UNIQUE INDEX recipes_project_id_name ON recipes (project_id, name);
--
-- Table: shop_sections
--
CREATE TABLE shop_sections (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id int NOT NULL,
  name text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX shop_sections_idx_project_id ON shop_sections (project_id);
CREATE UNIQUE INDEX shop_sections_project_id_name ON shop_sections (project_id, name);
--
-- Table: tag_groups
--
CREATE TABLE tag_groups (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id int NOT NULL,
  color int,
  name text NOT NULL,
  comment text NOT NULL DEFAULT '',
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX tag_groups_idx_project_id ON tag_groups (project_id);
CREATE UNIQUE INDEX tag_groups_project_id_name ON tag_groups (project_id, name);
--
-- Table: terms_users
--
CREATE TABLE terms_users (
  terms_id int NOT NULL,
  user_id int NOT NULL,
  approved datetime NOT NULL,
  PRIMARY KEY (terms_id, user_id),
  FOREIGN KEY (terms_id) REFERENCES terms(id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX terms_users_idx_terms_id ON terms_users (terms_id);
CREATE INDEX terms_users_idx_user_id ON terms_users (user_id);
--
-- Table: articles
--
CREATE TABLE articles (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id int NOT NULL,
  shop_section_id int,
  shelf_life_days int,
  preorder_servings int,
  preorder_workdays int,
  name text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (shop_section_id) REFERENCES shop_sections(id)
);
CREATE INDEX articles_idx_project_id ON articles (project_id);
CREATE INDEX articles_idx_shop_section_id ON articles (shop_section_id);
CREATE UNIQUE INDEX articles_project_id_name ON articles (project_id, name);
--
-- Table: organizations_projects
--
CREATE TABLE organizations_projects (
  organization_id int NOT NULL,
  project_id int NOT NULL,
  role text NOT NULL,
  PRIMARY KEY (organization_id, project_id),
  FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX organizations_projects_idx_organization_id ON organizations_projects (organization_id);
CREATE INDEX organizations_projects_idx_project_id ON organizations_projects (project_id);
--
-- Table: quantities
--
CREATE TABLE quantities (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id int NOT NULL,
  name text NOT NULL,
  default_unit_id int,
  FOREIGN KEY (default_unit_id) REFERENCES units(id),
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);
CREATE INDEX quantities_idx_default_unit_id ON quantities (default_unit_id);
CREATE INDEX quantities_idx_project_id ON quantities (project_id);
CREATE UNIQUE INDEX quantities_project_id_name ON quantities (project_id, name);
--
-- Table: tags
--
CREATE TABLE tags (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id int NOT NULL,
  tag_group_id int,
  name text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_group_id) REFERENCES tag_groups(id)
);
CREATE INDEX tags_idx_project_id ON tags (project_id);
CREATE INDEX tags_idx_tag_group_id ON tags (tag_group_id);
CREATE UNIQUE INDEX tags_project_id_name ON tags (project_id, name);
--
-- Table: units
--
CREATE TABLE units (
  id INTEGER PRIMARY KEY NOT NULL,
  project_id int NOT NULL,
  quantity_id int NOT NULL,
  to_quantity_default real,
  space bool NOT NULL,
  short_name text NOT NULL,
  long_name text NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (quantity_id) REFERENCES quantities(id)
);
CREATE INDEX units_idx_project_id ON units (project_id);
CREATE INDEX units_idx_quantity_id ON units (quantity_id);
CREATE UNIQUE INDEX units_project_id_long_name ON units (project_id, long_name);
--
-- Table: dishes
--
CREATE TABLE dishes (
  id INTEGER PRIMARY KEY NOT NULL,
  meal_id int NOT NULL,
  from_recipe_id int,
  name text NOT NULL,
  servings int NOT NULL,
  prepare_at_meal_id int,
  preparation text NOT NULL,
  description text NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
  FOREIGN KEY (prepare_at_meal_id) REFERENCES meals(id),
  FOREIGN KEY (from_recipe_id) REFERENCES recipes(id)
);
CREATE INDEX dishes_idx_meal_id ON dishes (meal_id);
CREATE INDEX dishes_idx_prepare_at_meal_id ON dishes (prepare_at_meal_id);
CREATE INDEX dishes_idx_from_recipe_id ON dishes (from_recipe_id);
--
-- Table: recipes_tags
--
CREATE TABLE recipes_tags (
  recipe_id int NOT NULL,
  tag_id int NOT NULL,
  PRIMARY KEY (recipe_id, tag_id),
  FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);
CREATE INDEX recipes_tags_idx_recipe_id ON recipes_tags (recipe_id);
CREATE INDEX recipes_tags_idx_tag_id ON recipes_tags (tag_id);
--
-- Table: articles_tags
--
CREATE TABLE articles_tags (
  article_id int NOT NULL,
  tag_id int NOT NULL,
  PRIMARY KEY (article_id, tag_id),
  FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);
CREATE INDEX articles_tags_idx_article_id ON articles_tags (article_id);
CREATE INDEX articles_tags_idx_tag_id ON articles_tags (tag_id);
--
-- Table: articles_units
--
CREATE TABLE articles_units (
  article_id int NOT NULL,
  unit_id int NOT NULL,
  PRIMARY KEY (article_id, unit_id),
  FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
  FOREIGN KEY (unit_id) REFERENCES units(id)
);
CREATE INDEX articles_units_idx_article_id ON articles_units (article_id);
CREATE INDEX articles_units_idx_unit_id ON articles_units (unit_id);
--
-- Table: dishes_tags
--
CREATE TABLE dishes_tags (
  dish_id int NOT NULL,
  tag_id int NOT NULL,
  PRIMARY KEY (dish_id, tag_id),
  FOREIGN KEY (dish_id) REFERENCES dishes(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);
CREATE INDEX dishes_tags_idx_dish_id ON dishes_tags (dish_id);
CREATE INDEX dishes_tags_idx_tag_id ON dishes_tags (tag_id);
--
-- Table: items
--
CREATE TABLE items (
  id INTEGER PRIMARY KEY NOT NULL,
  purchase_list_id int NOT NULL,
  value real NOT NULL,
  offset real NOT NULL DEFAULT 0,
  unit_id int NOT NULL,
  article_id int NOT NULL,
  purchased bool NOT NULL DEFAULT '0',
  comment text NOT NULL,
  FOREIGN KEY (article_id) REFERENCES articles(id),
  FOREIGN KEY (article_id, unit_id) REFERENCES articles_units(article_id, unit_id),
  FOREIGN KEY (purchase_list_id) REFERENCES purchase_lists(id) ON DELETE CASCADE,
  FOREIGN KEY (unit_id) REFERENCES units(id)
);
CREATE INDEX items_idx_article_id ON items (article_id);
CREATE INDEX items_idx_article_id_unit_id ON items (article_id, unit_id);
CREATE INDEX items_idx_purchase_list_id ON items (purchase_list_id);
CREATE INDEX items_idx_unit_id ON items (unit_id);
CREATE UNIQUE INDEX items_purchase_list_id_article_id_unit_id ON items (purchase_list_id, article_id, unit_id);
--
-- Table: recipe_ingredients
--
CREATE TABLE recipe_ingredients (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  recipe_id int NOT NULL,
  prepare bool NOT NULL,
  article_id int NOT NULL,
  unit_id int NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (article_id) REFERENCES articles(id),
  FOREIGN KEY (article_id, unit_id) REFERENCES articles_units(article_id, unit_id),
  FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit_id) REFERENCES units(id)
);
CREATE INDEX recipe_ingredients_idx_article_id ON recipe_ingredients (article_id);
CREATE INDEX recipe_ingredients_idx_article_id_unit_id ON recipe_ingredients (article_id, unit_id);
CREATE INDEX recipe_ingredients_idx_recipe_id ON recipe_ingredients (recipe_id);
CREATE INDEX recipe_ingredients_idx_unit_id ON recipe_ingredients (unit_id);
--
-- Table: dish_ingredients
--
CREATE TABLE dish_ingredients (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  dish_id int NOT NULL,
  prepare bool NOT NULL,
  article_id int NOT NULL,
  unit_id int NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  item_id int,
  FOREIGN KEY (article_id) REFERENCES articles(id),
  FOREIGN KEY (article_id, unit_id) REFERENCES articles_units(article_id, unit_id),
  FOREIGN KEY (dish_id) REFERENCES dishes(id) ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE SET NULL,
  FOREIGN KEY (unit_id) REFERENCES units(id)
);
CREATE INDEX dish_ingredients_idx_article_id ON dish_ingredients (article_id);
CREATE INDEX dish_ingredients_idx_article_id_unit_id ON dish_ingredients (article_id, unit_id);
CREATE INDEX dish_ingredients_idx_dish_id ON dish_ingredients (dish_id);
CREATE INDEX dish_ingredients_idx_item_id ON dish_ingredients (item_id);
CREATE INDEX dish_ingredients_idx_unit_id ON dish_ingredients (unit_id);
COMMIT;
