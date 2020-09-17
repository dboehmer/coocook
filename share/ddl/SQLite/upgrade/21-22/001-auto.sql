-- Convert schema 'share/ddl/_source/deploy/21/001-auto.yml' to 'share/ddl/_source/deploy/22/001-auto.yml':;

;
BEGIN;

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
CREATE UNIQUE INDEX blacklist_emails_email_fc02 ON blacklist_emails (email_fc);

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
CREATE UNIQUE INDEX blacklist_usernames_usernam00 ON blacklist_usernames (username_fc);

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
CREATE INDEX dish_ingredients_idx_articl00 ON dish_ingredients (article_id);

;
CREATE INDEX dish_ingredients_idx_articl00 ON dish_ingredients (article_id, unit_id);

;
CREATE INDEX dish_ingredients_idx_dish_id02 ON dish_ingredients (dish_id);

;
CREATE INDEX dish_ingredients_idx_item_id02 ON dish_ingredients (item_id);

;
CREATE INDEX dish_ingredients_idx_unit_id02 ON dish_ingredients (unit_id);

;
INSERT INTO dish_ingredients SELECT id, position, dish_id, prepare, article_id, unit_id, value, comment, item_id FROM dish_ingredients_temp_alter;

;
DROP TABLE dish_ingredients_temp_alter;

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
CREATE INDEX items_idx_article_id02 ON items (article_id);

;
CREATE INDEX items_idx_article_id_unit_id02 ON items (article_id, unit_id);

;
CREATE INDEX items_idx_purchase_list_id02 ON items (purchase_list_id);

;
CREATE INDEX items_idx_unit_id02 ON items (unit_id);

;
CREATE UNIQUE INDEX items_purchase_list_id_arti00 ON items (purchase_list_id, article_id, unit_id);

;
INSERT INTO items SELECT id, purchase_list_id, value, offset, unit_id, article_id, purchased, comment FROM items_temp_alter;

;
DROP TABLE items_temp_alter;

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
CREATE INDEX organizations_idx_owner_id02 ON organizations (owner_id);

;
CREATE UNIQUE INDEX organizations_name02 ON organizations (name);

;
CREATE UNIQUE INDEX organizations_name_fc02 ON organizations (name_fc);

;
INSERT INTO organizations SELECT id, name, name_fc, owner_id, description_md, display_name, admin_comment, created FROM organizations_temp_alter;

;
DROP TABLE organizations_temp_alter;

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
CREATE INDEX projects_idx_owner_id02 ON projects (owner_id);

;
CREATE UNIQUE INDEX projects_name02 ON projects (name);

;
CREATE UNIQUE INDEX projects_url_name02 ON projects (url_name);

;
CREATE UNIQUE INDEX projects_url_name_fc02 ON projects (url_name_fc);

;
INSERT INTO projects SELECT id, name, url_name, url_name_fc, description, is_public, owner_id, created, archived FROM projects_temp_alter;

;
DROP TABLE projects_temp_alter;

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
CREATE INDEX recipe_ingredients_idx_arti00 ON recipe_ingredients (article_id);

;
CREATE INDEX recipe_ingredients_idx_arti00 ON recipe_ingredients (article_id, unit_id);

;
CREATE INDEX recipe_ingredients_idx_reci00 ON recipe_ingredients (recipe_id);

;
CREATE INDEX recipe_ingredients_idx_unit00 ON recipe_ingredients (unit_id);

;
INSERT INTO recipe_ingredients SELECT id, position, recipe_id, prepare, article_id, unit_id, value, comment FROM recipe_ingredients_temp_alter;

;
DROP TABLE recipe_ingredients_temp_alter;

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
CREATE INDEX terms_users_idx_terms_id02 ON terms_users (terms_id);

;
CREATE INDEX terms_users_idx_user_id02 ON terms_users (user_id);

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
CREATE INDEX units_idx_project_id02 ON units (project_id);

;
CREATE INDEX units_idx_quantity_id02 ON units (quantity_id);

;
CREATE UNIQUE INDEX units_project_id_long_name02 ON units (project_id, long_name);

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
CREATE UNIQUE INDEX users_email_fc02 ON users (email_fc);

;
CREATE UNIQUE INDEX users_name02 ON users (name);

;
CREATE UNIQUE INDEX users_name_fc02 ON users (name_fc);

;
CREATE UNIQUE INDEX users_password_hash02 ON users (password_hash);

;
CREATE UNIQUE INDEX users_token_hash02 ON users (token_hash);

;
INSERT INTO users SELECT id, name, name_fc, password_hash, display_name, admin_comment, email_fc, email_verified, token_hash, token_expires, created FROM users_temp_alter;

;
DROP TABLE users_temp_alter;

;

COMMIT;

