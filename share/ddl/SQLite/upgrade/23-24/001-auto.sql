-- Convert schema 'share/ddl/_source/deploy/23/001-auto.yml' to 'share/ddl/_source/deploy/24/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE users_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  name_fc text NOT NULL,
  password_hash text NOT NULL,
  display_name text NOT NULL,
  admin_comment text NOT NULL DEFAULT '',
  email_fc text NOT NULL,
  new_email_fc text,
  email_verified timestamp without time zone,
  token_hash text,
  token_created timestamp without time zone,
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
  new_email_fc text,
  email_verified timestamp without time zone,
  token_hash text,
  token_created timestamp without time zone,
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
INSERT INTO users SELECT id, name, name_fc, password_hash, display_name, admin_comment, email_fc, new_email_fc, email_verified, token_hash, token_created, token_expires, created FROM users_temp_alter;

;
DROP TABLE users_temp_alter;

;

COMMIT;

