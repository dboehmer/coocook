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

INSERT INTO users_temp_alter( id, name, name_fc, password_hash, display_name, admin_comment, email, email_verified, token_hash, token_expires, created) SELECT id, name, name_fc, password_hash, display_name, admin_comment, email, email_verified, token_hash, token_expires, created FROM users;

DROP TABLE users;

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

-- LOWER() should be the same as fc() for valid email addresses
INSERT INTO users SELECT id, name, name_fc, password_hash, display_name, admin_comment, LOWER(email), email_verified, token_hash, token_expires, created FROM users_temp_alter;

DROP TABLE users_temp_alter;

