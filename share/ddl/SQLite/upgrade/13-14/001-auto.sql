-- Convert schema 'share/ddl/_source/deploy/13/001-auto.yml' to 'share/ddl/_source/deploy/14/001-auto.yml':;

BEGIN;

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
  token_expires datetime
);

INSERT INTO users_temp_alter( id, name, name_fc, password_hash, display_name, email, email_verified, token_hash, token_expires) SELECT id, name, name_fc, password_hash, display_name, email, email_verified, token_hash, token_expires FROM users;

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
  token_expires datetime
);

CREATE UNIQUE INDEX users_email02 ON users (email);

CREATE UNIQUE INDEX users_name02 ON users (name);

CREATE UNIQUE INDEX users_name_fc02 ON users (name_fc);

CREATE UNIQUE INDEX users_password_hash02 ON users (password_hash);

CREATE UNIQUE INDEX users_token_hash02 ON users (token_hash);

INSERT INTO users SELECT id, name, name_fc, password_hash, display_name, admin_comment, email, email_verified, token_hash, token_expires FROM users_temp_alter;

DROP TABLE users_temp_alter;

COMMIT;
