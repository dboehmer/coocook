-- Convert schema 'share/ddl/_source/deploy/14/001-auto.yml' to 'share/ddl/_source/deploy/15/001-auto.yml':;

BEGIN;

CREATE TEMPORARY TABLE projects_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  url_name text NOT NULL,
  url_name_fc text NOT NULL,
  description text NOT NULL,
  is_public bool NOT NULL DEFAULT '1',
  owner int NOT NULL,
  created datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner) REFERENCES users(id)
);

INSERT INTO projects_temp_alter( id, name, url_name, url_name_fc, description, is_public, owner, created ) SELECT id, name, url_name, url_name_fc, description, is_public, owner, (
    SELECT DATETIME( (
        SELECT date FROM meals WHERE meals.project = projects.id
        UNION
        SELECT date FROM purchase_lists WHERE purchase_lists.project = projects.id
        UNION
        SELECT CURRENT_TIMESTAMP
    ) ) AS date
    ORDER BY date ASC
    LIMIT 1
) FROM projects;

DROP TABLE projects;

CREATE TABLE projects (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  url_name text NOT NULL,
  url_name_fc text NOT NULL,
  description text NOT NULL,
  is_public bool NOT NULL DEFAULT '1',
  owner int NOT NULL,
  created datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner) REFERENCES users(id)
);

CREATE INDEX projects_idx_owner02 ON projects (owner);

CREATE UNIQUE INDEX projects_name02 ON projects (name);

CREATE UNIQUE INDEX projects_url_name02 ON projects (url_name);

CREATE UNIQUE INDEX projects_url_name_fc02 ON projects (url_name_fc);

INSERT INTO projects SELECT id, name, url_name, url_name_fc, description, is_public, owner, created FROM projects_temp_alter;

DROP TABLE projects_temp_alter;

CREATE TEMPORARY TABLE users_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  name_fc text NOT NULL,
  password_hash text NOT NULL,
  display_name text NOT NULL,
  admin_comment text NOT NULL DEFAULT '',
  email text NOT NULL,
  email_verified datetime,
  token_hash text,
  token_expires datetime,
  created datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users_temp_alter( id, name, name_fc, password_hash, display_name, admin_comment, email, email_verified, token_hash, token_expires, created ) SELECT id, name, name_fc, password_hash, display_name, admin_comment, email, email_verified, token_hash, token_expires, (
    SELECT (
        SELECT created FROM projects WHERE owner = users.id
        UNION
        SELECT CURRENT_TIMESTAMP
    ) AS created
    ORDER BY created ASC
    LIMIT 1
) FROM users;

DROP TABLE users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  name_fc text NOT NULL,
  password_hash text NOT NULL,
  display_name text NOT NULL,
  admin_comment text NOT NULL DEFAULT '',
  email text NOT NULL,
  email_verified datetime,
  token_hash text,
  token_expires datetime,
  created datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX users_email02 ON users (email);

CREATE UNIQUE INDEX users_name02 ON users (name);

CREATE UNIQUE INDEX users_name_fc02 ON users (name_fc);

CREATE UNIQUE INDEX users_password_hash02 ON users (password_hash);

CREATE UNIQUE INDEX users_token_hash02 ON users (token_hash);

INSERT INTO users SELECT id, name, name_fc, password_hash, display_name, admin_comment, email, email_verified, token_hash, token_expires, created FROM users_temp_alter;

DROP TABLE users_temp_alter;

COMMIT;
