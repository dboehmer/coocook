-- Convert schema 'share/ddl/_source/deploy/8/001-auto.yml' to 'share/ddl/_source/deploy/9/001-auto.yml':;

BEGIN;

CREATE TEMPORARY TABLE users_temp_alter (
  id,
  name,
  password_hash,
  display_name,
  email,
  email_verified,
  token_hash,
  token_expires
);

INSERT INTO users_temp_alter
SELECT * FROM users;

DROP TABLE users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  name_fc text NOT NULL,
  password_hash text NOT NULL,
  display_name text NOT NULL,
  email text NOT NULL,
  email_verified datetime,
  token_hash text,
  token_expires datetime
);

CREATE UNIQUE INDEX users_email ON users (email);
CREATE UNIQUE INDEX users_name ON users (name);
CREATE UNIQUE INDEX users_name_fc ON users (name_fc);
CREATE UNIQUE INDEX users_token_hash ON users (token_hash);

INSERT INTO users
SELECT
  id,
  name,

  -- because of NOT NULL constraint for name_fc
  name,

  password_hash,
  display_name,
  email,
  email_verified,
  token_hash,
  token_expires
FROM users_temp_alter;

DROP TABLE users_temp_alter;

COMMIT;
